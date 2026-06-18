class AddDesignToPersonWhiteLabels < ActiveRecord::Migration[5.2]
  def change
    add_column :person_white_labels, :design, :string
  end
end
