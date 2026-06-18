class AddDomainToPersonWhiteLabels < ActiveRecord::Migration[5.1]
  def change
    add_column :person_white_labels, :domain, :string
  end
end
