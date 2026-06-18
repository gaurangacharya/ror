module MarketplaceService
  module Listing
    ListingModel = ::Listing

    module Entity
      Listing = EntityUtils.define_builder(
        %i[id mandatory fixnum],
        %i[title mandatory string],
        %i[author_id mandatory string],
        %i[price optional money],
        %i[require_shipping_address optional to_bool],
        %i[pickup_enabled optional to_bool],
        %i[shipping_price optional money],
        %i[shipping_price_additional optional money],
        %i[quantity optional string],
        %i[transaction_process_id mandatory fixnum],
        %i[unit_type optional to_symbol],
        %i[unit_tr_key optional string],
        %i[unit_selector_tr_key optional string],
        %i[action_button_tr_key string],
        %i[deleted to_bool]
      )

      module_function

      def listing(listing_model)
        Listing.call(EntityUtils.model_to_hash(listing_model).merge({ price: listing_model.price,
                                                                      shipping_price: listing_model.shipping_price, shipping_price_additional: listing_model.shipping_price_additional }))
      end

      def send_payment_settings_reminder?(listing_id, community_id)
        listing = ListingModel.find(listing_id)
        payment_type = MarketplaceService::Community::Query.payment_type(community_id)

        query_info = {
          transaction: {
            payment_gateway: payment_type,
            listing_author_id: listing.author.id,
            community_id: community_id
          }
        }

        opts = {
          community_id: community_id,
          process_id: listing.transaction_process_id
        }

        process = TransactionService::API::Api.processes.get(community_id: community_id,
                                                             process_id: listing.transaction_process_id)
                                              .maybe[:process].or_else(nil)

        raise ArgumentError, "Cannot find transaction process: #{opts}" if process.nil?

        payment_type && process == :preauthorize &&
          !TransactionService::Transaction.can_start_transaction(query_info, listing).data[:result]
      end
    end

    module Command
      module_function

      #
      # DELETE /listings/:author_id
      def delete_listings(author_id)
        listings = ListingModel.where(author_id:)
        listings.update_all(
          # Delete listing info
          description: nil,
          origin: nil,
          open: false,

          deleted: true
        )

        ids = listings.pluck(:id)
        ListingImage.where(listing_id: ids).destroy_all

        Result::Success.new
      end
    end

    module Query
      module_function

      def listing(listing_id)
        listing_model = ListingModel.find(listing_id)
        MarketplaceService::Listing::Entity.listing(listing_model)
      end
    end
  end
end
