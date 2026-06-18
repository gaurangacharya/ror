class CreateFareharborFailures < ActiveRecord::Migration[5.2]
  def change
    create_table :fareharbor_failures do |t|
      t.string :fareharbor_shortname
      t.string :fareharbor_item
      t.text :exception

      t.timestamps
    end
  end
end
