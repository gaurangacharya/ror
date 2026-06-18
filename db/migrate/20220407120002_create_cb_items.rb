class CreateCbItems < ActiveRecord::Migration[5.1]
  def change
    create_table :cb_items do |t|
      t.string :item_id
      t.string :name
      t.text :description
      t.string :status
      t.text :chargebee_data

      t.timestamps
    end
  end
end
