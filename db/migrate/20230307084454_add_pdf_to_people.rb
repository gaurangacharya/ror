class AddPdfToPeople < ActiveRecord::Migration[5.1]
  def change
    add_attachment :people, :pdf
    add_column :people, :embed_document, :string, limit: 1024
  end
end
