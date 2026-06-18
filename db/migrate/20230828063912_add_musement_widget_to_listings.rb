class AddMusementWidgetToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :musement_widget_id, :string
  end
end
