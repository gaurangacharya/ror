# == Schema Information
#
# Table name: browser_fingerprint_usages
#
#  id                     :integer          not null, primary key
#  browser_fingerprint_id :integer
#  ip_address             :string(255)
#  person_id              :string(255)
#  last_seen_at           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_browser_fingerprint_usages_on_browser_fingerprint_id  (browser_fingerprint_id)
#

class BrowserFingerprintUsage < ApplicationRecord
  belongs_to :browser_fingerprint
  belongs_to :person
end
