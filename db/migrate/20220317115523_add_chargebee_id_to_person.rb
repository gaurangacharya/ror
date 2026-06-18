class AddChargebeeIdToPerson < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :chargebee_id, :string
    add_column :people, :event_last_modified_at, :datetime
    add_column :people, :chargebee_data, :text
  end
end
