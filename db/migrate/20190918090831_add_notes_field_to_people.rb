class AddNotesFieldToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :notes, :string
  end
end
