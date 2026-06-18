class CreatePaypalSoapAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :paypal_soap_accounts do |t|
      t.string :person_id, limit: 22, index: true
      t.string :login
      t.string :password
      t.string :signature

      t.timestamps
    end
  end
end
