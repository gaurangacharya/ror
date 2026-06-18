class CreateDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.integer :listing_id
      t.integer :transaction_id
      t.string :person_id, limit: 22
      t.string :person_role
      t.string :document_role
      t.string :doc_type
      t.string :docusign_id
      t.attachment :document
      t.timestamps
    end
  end
end
