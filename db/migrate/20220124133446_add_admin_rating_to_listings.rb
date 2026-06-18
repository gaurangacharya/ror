class AddAdminRatingToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :admin_rating, :integer, default: 0
  end
end
