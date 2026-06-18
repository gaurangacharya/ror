class AddFaviconToPersonWhiteLabels < ActiveRecord::Migration[5.1]
  def change
    add_column :person_white_labels, :favicon_file_name, :string
    add_column :person_white_labels, :favicon_content_type, :string
    add_column :person_white_labels, :favicon_file_size, :integer
    add_column :person_white_labels, :favicon_processing, :boolean
  end
end
