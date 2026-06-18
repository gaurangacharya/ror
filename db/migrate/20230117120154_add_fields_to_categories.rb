class AddFieldsToCategories < ActiveRecord::Migration[5.1]
  def change
    add_column :categories, :quick_filter, :boolean, default: false
  end
end
