class AddIsAffiliateFieldToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :is_affiliate, :boolean, default: false
  end
end
