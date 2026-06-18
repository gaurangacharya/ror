class AddNameOnReservationToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :name_on_reservation, :string
  end
end
