class AddCommunityAuthorToReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :reviews, :community_id, :integer
    add_index :reviews, :community_id
    add_column :reviews, :author, :string
  end
end
