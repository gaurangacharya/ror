class AddWebsiteUrlToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :website_url, :string
  end
end
