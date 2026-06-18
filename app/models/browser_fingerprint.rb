# == Schema Information
#
# Table name: browser_fingerprints
#
#  id         :integer          not null, primary key
#  hash_code  :string(255)
#  user_agent :string(255)
#  last_ip    :string(255)
#  components :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BrowserFingerprint < ApplicationRecord
  has_many :usages, class_name: 'BrowserFingerprintUsage'
  serialize :components, Hash

  def self.record_usage(hash_code, components, ip_address, person)
    record = BrowserFingerprint.where(hash_code: hash_code).first_or_create
    record.user_agent = components['userAgent']
    record.last_ip = ip_address
    record.components = components
    record.save
    usage = BrowserFingerprintUsage.where(browser_fingerprint: record, person: person, ip_address: ip_address).first_or_create
    usage.last_seen_at = Time.zone.now
    usage.save
  end
end
