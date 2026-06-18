class CreatePersonFareharbors < ActiveRecord::Migration[5.2]
  def change
    create_table :person_fareharbors do |t|
      t.references :person, type: :string, limit: 22
      t.string :fareharbor_shortname
      t.integer :fareharbor_items
      t.integer :updated
      t.integer :failed
      t.integer :deleted
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end
