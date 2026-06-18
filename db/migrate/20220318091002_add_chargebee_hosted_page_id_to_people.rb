class AddChargebeeHostedPageIdToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :chargebee_hosted_page_id, :string
  end
end
