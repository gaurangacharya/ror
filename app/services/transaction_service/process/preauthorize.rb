# coding: utf-8
module TransactionService::Process
  Gateway = TransactionService::Gateway
  Worker = TransactionService::Worker
  ProcessStatus = TransactionService::DataTypes::ProcessStatus
  DataTypes = TransactionService::DataTypes::Transaction

  class Preauthorize

    TxStore = TransactionService::Store::Transaction

    def create(tx:, gateway_fields:, gateway_adapter:, force_sync:)
      Transition.transition_to(tx[:id], :initiated)
      tx[:current_state] = :initiated

      if !force_sync
        proc_token = Worker.enqueue_preauthorize_op(
          community_id: tx[:community_id],
          transaction_id: tx[:id],
          op_name: :do_create,
          op_input: [tx, gateway_fields])

        proc_status_response(proc_token)
      else
        do_create(tx, gateway_fields)
      end
    end

    def do_create(tx, gateway_fields)
      gateway_adapter = TransactionService::Transaction.gateway_adapter(tx[:payment_gateway])

      completion = gateway_adapter.create_payment(
        tx: tx,
        gateway_fields: gateway_fields,
        force_sync: true)

      Gateway.unwrap_completion(completion) do
        finalize_create(tx: tx, gateway_adapter: gateway_adapter, force_sync: true)
      end
    end

    def finalize_create(tx:, gateway_adapter:, force_sync:)
      ensure_can_execute!(tx: tx, allowed_states: [:initiated, :preauthorized])

      if !force_sync
        proc_token = Worker.enqueue_preauthorize_op(
          community_id: tx[:community_id],
          transaction_id: tx[:id],
          op_name: :do_finalize_create,
          op_input: [tx[:id], tx[:community_id]])

        proc_status_response(proc_token)
      else
        do_finalize_create(tx[:id], tx[:community_id])
      end
    end

    def do_finalize_create(transaction_id, community_id)
      tx = TxStore.get_in_community(community_id: community_id, transaction_id: transaction_id)
      gateway_adapter = TransactionService::Transaction.gateway_adapter(tx[:payment_gateway])

      res =
        if tx[:current_state] == :preauthorized
          Result::Success.new()
        else
          booking_res =
            if tx[:availability] == :booking && tx[:booking][:per_hour]
              Result::Success.new()
            elsif tx[:availability] == :booking
              # block slots
              DateTimeSlotService.initiate_booking(transaction_id)
              Result::Success.new()
            else
              Result::Success.new()
            end

          booking_res.on_success {
            Transition.transition_to(tx[:id], :preauthorized)
          }
        end

      res.and_then {
        Result::Success.new(DataTypes.create_transaction_response(tx))
      }
    end

    def reject(tx:, message:, sender_id:, gateway_adapter:, auto: false)
      res = Gateway.unwrap_completion(
        gateway_adapter.reject_payment(tx: tx, reason: "")) do

        Transition.transition_to(tx[:id], :rejected, {auto: auto})
      end

      if res[:success] && message.present?
        send_message(tx, message, sender_id)
      end

      res
    end

    def complete_preauthorization(tx:, message:, sender_id:, gateway_adapter:)
      res = Gateway.unwrap_completion(
        gateway_adapter.complete_preauthorization(tx: tx)) do

        Transition.transition_to(tx[:id], :paid)
        Transition.transition_to(tx[:id], :confirmed)
      end

      if res[:success] && message.present?
        send_message(tx, message, sender_id)
      end

      res
    end

    def complete(tx:, message:, sender_id:, gateway_adapter:)
      Transition.transition_to(tx[:id], :confirmed)
      TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                      transaction_id: tx[:id],
                                      person_id: tx[:listing_author_id])

      if message.present?
        send_message(tx, message, sender_id)
      end

      Result::Success.new({result: true})
    end

    def cancel(tx:, message:, sender_id:, gateway_adapter:)
      Transition.transition_to(tx[:id], :canceled)
      TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                      transaction_id: tx[:id],
                                      person_id: tx[:listing_author_id])

      if message.present?
        send_message(tx, message, sender_id)
      end

      Result::Success.new({result: true})
    end


    private

    def send_message(tx, message, sender_id)
      TxStore.add_message(community_id: tx[:community_id],
                          transaction_id: tx[:id],
                          message: message,
                          sender_id: sender_id)
    end

    def proc_status_response(proc_token)
      Result::Success.new(
        ProcessStatus.create_process_status({
                                              process_token: proc_token[:process_token],
                                              completed: proc_token[:op_completed],
                                              result: proc_token[:op_output]}))
    end

    def logger
      @logger ||= SharetribeLogger.new(:preauthorize_process)
    end

    def ensure_can_execute!(tx:, allowed_states:)
      tx_state = tx[:current_state]

      unless allowed_states.include?(tx_state)
        raise TransactionService::Transaction::IllegalTransactionStateException.new(
               "Transaction was in illegal state, expected state: [#{allowed_states.join(',')}], actual state: #{tx_state}")
      end
    end
  end
end
