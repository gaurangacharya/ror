class CreatePlans < ActiveRecord::Migration[5.1]
  def change
    create_table :plans do |t|
      t.string :name
      t.string :plan_id
      t.string :status
      t.text :chargebee_data

      t.timestamps
    end
  end
end
