class AddTripadvisorLocationIdToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :tripadvisor_location_id, :string
  end
end
