class AddDocumentIdToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :document_id, :integer
  end
end
