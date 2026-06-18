# -*- encoding: utf-8 -*-
# stub: airbrake-ruby 2.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "airbrake-ruby".freeze
  s.version = "2.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Airbrake Technologies, Inc.".freeze]
  s.date = "2018-10-11"
  s.description = "Airbrake Ruby is a plain Ruby notifier for Airbrake (https://airbrake.io), the\nleading exception reporting service. Airbrake Ruby provides minimalist API that\nenables the ability to send any Ruby exception to the Airbrake dashboard. The\nlibrary is extremely lightweight, contains no dependencies and perfectly suits\nplain Ruby applications. For apps that are built with Rails, Sinatra or any\nother Rack-compliant web framework we offer the airbrake gem\n(https://github.com/airbrake/airbrake). It has additional features such as\nreporting of any unhandled exceptions automatically, integrations with Resque,\nSidekiq, Delayed Job and many more.\n".freeze
  s.email = "support@airbrake.io".freeze
  s.homepage = "https://airbrake.io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Ruby notifier for https://airbrake.io".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10"])
      s.add_development_dependency(%q<pry>.freeze, ["~> 0"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 2.3"])
      s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2"])
      s.add_development_dependency(%q<public_suffix>.freeze, ["~> 2.0", "< 3.0"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3"])
      s.add_dependency(%q<rake>.freeze, ["~> 10"])
      s.add_dependency(%q<pry>.freeze, ["~> 0"])
      s.add_dependency(%q<webmock>.freeze, ["~> 2.3"])
      s.add_dependency(%q<benchmark-ips>.freeze, ["~> 2"])
      s.add_dependency(%q<public_suffix>.freeze, ["~> 2.0", "< 3.0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3"])
    s.add_dependency(%q<rake>.freeze, ["~> 10"])
    s.add_dependency(%q<pry>.freeze, ["~> 0"])
    s.add_dependency(%q<webmock>.freeze, ["~> 2.3"])
    s.add_dependency(%q<benchmark-ips>.freeze, ["~> 2"])
    s.add_dependency(%q<public_suffix>.freeze, ["~> 2.0", "< 3.0"])
  end
end
