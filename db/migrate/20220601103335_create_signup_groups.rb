class CreateSignupGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :signup_groups do |t|
      t.string :title
      t.integer :position, default: 0
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
