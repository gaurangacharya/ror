class AddSelfServicePriceToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :self_service_price_cents, :integer
  end
end
