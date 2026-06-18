class AddSortPriorityToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :sort_priority, :integer, default: 3
  end
end
