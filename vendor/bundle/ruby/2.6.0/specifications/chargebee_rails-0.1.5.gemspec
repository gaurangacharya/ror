# -*- encoding: utf-8 -*-
# stub: chargebee_rails 0.1.5 ruby lib

Gem::Specification.new do |s|
  s.name = "chargebee_rails".freeze
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chargebee".freeze, "Spritle".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-01-20"
  s.description = "This gem provides developers with the ability to easily\n                        integrate chargebee's subscription management into their\n                        application backed by active record models.".freeze
  s.email = ["chargebee@spritle.com".freeze]
  s.homepage = "https://github.com/spritlesoftware/chargebee-rails-subscriptions".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A subscription management gem for Rails with ChargeBee.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<chargebee>.freeze, ["~> 2.0", ">= 2.0.5"])
      s.add_development_dependency(%q<rails>.freeze, [">= 3.1"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
      s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<vcr>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    else
      s.add_dependency(%q<chargebee>.freeze, ["~> 2.0", ">= 2.0.5"])
      s.add_dependency(%q<rails>.freeze, [">= 3.1"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
      s.add_dependency(%q<webmock>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<vcr>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<chargebee>.freeze, ["~> 2.0", ">= 2.0.5"])
    s.add_dependency(%q<rails>.freeze, [">= 3.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.3.0"])
    s.add_dependency(%q<webmock>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<vcr>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end
