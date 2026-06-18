if Rails.env.development? || Rails.env.staging?
  ActiveMerchant::Billing::Base.mode = :test
end
