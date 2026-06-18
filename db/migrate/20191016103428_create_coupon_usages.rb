class CreateCouponUsages < ActiveRecord::Migration[5.1]
  def change
    create_table :coupon_usages do |t|
      t.integer :coupon_id
      t.integer :value
      t.string :person_id

      t.timestamps
    end
  end
end
