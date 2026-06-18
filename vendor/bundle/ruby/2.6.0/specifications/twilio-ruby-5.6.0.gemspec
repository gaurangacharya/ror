# -*- encoding: utf-8 -*-
# stub: twilio-ruby 5.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "twilio-ruby".freeze
  s.version = "5.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "yard.run" => "yri" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Twilio API Team".freeze]
  s.date = "2017-12-16"
  s.description = "A simple library for communicating with the Twilio REST API, building TwiML, and generating Twilio JWT Capability Tokens".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE.md".freeze]
  s.files = ["LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "http://github.com/twilio/twilio-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "twilio-ruby".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A simple library for communicating with the Twilio REST API, building TwiML, and generating Twilio JWT Capability Tokens".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.5", "<= 2.5"])
      s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.6", "< 2.0"])
      s.add_runtime_dependency(%q<faraday>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.49.1"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.9"])
    else
      s.add_dependency(%q<jwt>.freeze, [">= 1.5", "<= 2.5"])
      s.add_dependency(%q<nokogiri>.freeze, [">= 1.6", "< 2.0"])
      s.add_dependency(%q<faraday>.freeze, ["~> 0.9"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.49.1"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.9.9"])
    end
  else
    s.add_dependency(%q<jwt>.freeze, [">= 1.5", "<= 2.5"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.6", "< 2.0"])
    s.add_dependency(%q<faraday>.freeze, ["~> 0.9"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.49.1"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.9"])
  end
end
