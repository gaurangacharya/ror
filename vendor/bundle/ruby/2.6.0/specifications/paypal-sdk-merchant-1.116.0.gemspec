# -*- encoding: utf-8 -*-
# stub: paypal-sdk-merchant 1.116.0 ruby lib

Gem::Specification.new do |s|
  s.name = "paypal-sdk-merchant".freeze
  s.version = "1.116.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["PayPal".freeze]
  s.date = "2014-07-23"
  s.description = "The PayPal Merchant SDK provides Ruby APIs for processing payments, recurring payments, subscriptions and transactions using PayPal's Merchant APIs, which include Express Checkout, Recurring Payments, Direct Payment and Transactional APIs.".freeze
  s.email = ["DL-PP-Platform-Ruby-SDK@ebay.com".freeze]
  s.homepage = "https://developer.paypal.com".freeze
  s.licenses = ["PayPal SDK License".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "PayPal Merchant SDK".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<paypal-sdk-core>.freeze, ["~> 0.3.0"])
    else
      s.add_dependency(%q<paypal-sdk-core>.freeze, ["~> 0.3.0"])
    end
  else
    s.add_dependency(%q<paypal-sdk-core>.freeze, ["~> 0.3.0"])
  end
end
