class AddEmailPublicToPersonWhiteLabel < ActiveRecord::Migration[5.2]
  def change
    add_column :person_white_labels, :email_public, :boolean, default: false
  end
end
