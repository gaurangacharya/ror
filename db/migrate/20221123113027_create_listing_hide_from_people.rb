class CreateListingHideFromPeople < ActiveRecord::Migration[5.1]
  def change
    create_table :listing_hide_from_people, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :listing
      t.references :person, type: :string, limit: 22

      t.timestamps
    end
  end
end
