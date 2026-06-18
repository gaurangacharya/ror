class CreateCoupons < ActiveRecord::Migration[5.1]
  def change
    create_table :coupons do |t|
      t.integer :community_id
      t.integer :value
      t.string :code
      t.boolean :is_active
      t.date :valid_until

      t.timestamps
    end
  end
end
