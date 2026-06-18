class AddCommunityIdToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :community_id, :integer
  end
end
