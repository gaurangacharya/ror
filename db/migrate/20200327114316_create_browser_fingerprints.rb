class CreateBrowserFingerprints < ActiveRecord::Migration[5.1]
  def change
    create_table :browser_fingerprints do |t|
      t.string :hash_code
      t.string :user_agent
      t.string :last_ip
      t.text :components

      t.timestamps
    end
  end
end
