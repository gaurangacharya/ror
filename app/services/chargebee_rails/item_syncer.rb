module ChargebeeRails
  class ItemSyncer
    attr_accessor :messages

    def self.sync(create:true, update:true, delete:false)
      syncer = new
      return syncer.do_sync(create:create, update:update, delete:delete)
    end

    def do_sync(create:true, update:true, delete:false)
      self.get_items
      self.sync_items(create:create, update:update, delete:delete)

      return messages
    end

    protected

    def output(message)
      puts(message)
      self.messages ||= []
      self.messages << message
    end

    def get_items
      loop do
        item_list = retrieve_item_list
        @offset = item_list.next_offset
        cb_items << item_list.map{|x| x.item}
        break unless @offset.present?
      end
      @cb_items = cb_items.flatten
    end

    def cb_items
      @cb_items ||= []
    end

    def sync_items(create:true, update:true, delete:false)
      output "Removed #{remove_items.count} item(s)" if (delete)
      output "Created #{create_new_items.count} item(s)" if (create)
      output "Updated all #{update_all_items.count} item(s)" if (update)
    end

    # Retrieve the item list from chargebee
    def retrieve_item_list
      options = { limit: 100 }
      options[:offset] = @offset if @offset.present?
      ChargeBee::Item.list(options)
    end

    # Remove items from application that do not exist in chargebee
    def remove_items
      cb_item_ids = cb_items.flat_map(&:id)
      CbItem.all.reject { |item| cb_item_ids.include?(item.item_id) }
              .each   { |item| output "Deleting CbItem - #{item.item_id}"; item.destroy }
    end

    # Create new items that are not present in app but are available in chargebee
    def create_new_items
      item_ids = CbItem.all.map(&:item_id)
      cb_items.reject { |cb_item| item_ids.include?(cb_item.id) }
              .each   { |new_item| output "Creating CbItem - #{new_item.id}"; CbItem.create(item_params(new_item)) }
    end

    # Update all existing items in the application
    def update_all_items
      cb_items.map do |cb_item|
        CbItem.find_by(item_id: cb_item.id).update(item_params(cb_item))
      end
    end

    # Build the item params to be created or updated in the application
    def item_params item
      {
        name: item.name,
        item_id: item.id,
        description: item.description,
        status: item.status,
        chargebee_data: {
          item_family_id: item.item_family_id,
          is_shippable: item.is_shippable,
          is_giftable: item.is_giftable,
          redirect_url: item.redirect_url,
          enabled_for_checkout: item.enabled_for_checkout,
          enabled_in_portal: item.enabled_in_portal,
        }
      }
    end
  end
end
