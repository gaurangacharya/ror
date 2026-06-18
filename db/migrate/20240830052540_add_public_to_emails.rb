class AddPublicToEmails < ActiveRecord::Migration[5.2]
  def change
    add_column :emails, :public, :boolean, default: false
  end
end
