class AddEmbedDocumentToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :embed_document, :string, limit: 1024
  end
end
