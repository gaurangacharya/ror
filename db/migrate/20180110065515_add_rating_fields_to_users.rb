class AddRatingFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :rating_average, :float, default: 0
    add_column :people, :rating_count, :integer, default: 0
  end
end
