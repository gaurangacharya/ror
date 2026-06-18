class AddWelcomeMemberEmailContentToCommunityCustomization < ActiveRecord::Migration[5.1]
  def change
    add_column :community_customizations, :welcome_member_email_content, :text, :limit => 16777215
  end
end
