class AddVendorIndividualFlagToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :is_vendor, :boolean, default: false
  end
end
