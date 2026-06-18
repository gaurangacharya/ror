class AddReferrerIdToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :referrer_id, :string
  end
end
