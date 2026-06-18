class CreateDocusignAuthorizations < ActiveRecord::Migration[5.1]
  def change
    create_table :docusign_authorizations do |t|
      t.integer :community_id
      t.string :person_id, limit: 22
      t.string :access_token, limit: 1024
      t.string :refresh_token, limit: 1024
      t.datetime :expires_at
      t.timestamps
    end
  end
end
