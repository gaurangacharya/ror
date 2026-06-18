class AddButtonColorToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :embed_document_button_color, :string
  end
end
