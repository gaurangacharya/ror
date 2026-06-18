class AddNameOnReservationToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :name_on_reservation, :boolean
  end
end
