class CreateBrowserFingerprintUsages < ActiveRecord::Migration[5.1]
  def change
    create_table :browser_fingerprint_usages do |t|
      t.belongs_to :browser_fingerprint, class_name: 'BrowserFingerprint', foreign_key: 'fingerprint_id'
      t.string :ip_address
      t.string :person_id
      t.datetime :last_seen_at
      t.timestamps
    end
  end
end
