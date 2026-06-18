module TransactionService::Process
  class Free

    def create(tx:, gateway_fields:, gateway_adapter:, force_sync:, auto: false)
      MarketplaceService::Transaction::Command.transition_to(tx[:id], :free)
      SendFreeReceipts.perform_later(tx[:id])
      Result::Success.new({result: true})
    end

  end
end
