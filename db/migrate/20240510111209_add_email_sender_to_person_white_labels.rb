class AddEmailSenderToPersonWhiteLabels < ActiveRecord::Migration[5.2]
  def change
    add_column :person_white_labels, :email_sender, :string
  end
end
