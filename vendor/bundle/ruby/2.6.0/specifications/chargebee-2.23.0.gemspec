# -*- encoding: utf-8 -*-
# stub: chargebee 2.23.0 ruby lib

Gem::Specification.new do |s|
  s.name = "chargebee".freeze
  s.version = "2.23.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rajaraman S".freeze, "Thiyagarajan T".freeze]
  s.date = "2023-02-17"
  s.description = "Subscription Billing - Simple. Secure. Affordable. More details at www.chargebee.com.".freeze
  s.email = ["rr@chargebee.com".freeze, "thiyagu@chargebee.com".freeze]
  s.extra_rdoc_files = ["README.rdoc".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.rdoc".freeze]
  s.homepage = "https://apidocs.chargebee.com/api/docs?lang=ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Ruby client for Chargebee API.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json_pure>.freeze, ["~> 2.1"])
      s.add_runtime_dependency(%q<rest-client>.freeze, [">= 1.8", "<= 2.0.2"])
      s.add_runtime_dependency(%q<cgi>.freeze, [">= 0.1.0", "< 1.0.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0.0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
    else
      s.add_dependency(%q<json_pure>.freeze, ["~> 2.1"])
      s.add_dependency(%q<rest-client>.freeze, [">= 1.8", "<= 2.0.2"])
      s.add_dependency(%q<cgi>.freeze, [">= 0.1.0", "< 1.0.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<json_pure>.freeze, ["~> 2.1"])
    s.add_dependency(%q<rest-client>.freeze, [">= 1.8", "<= 2.0.2"])
    s.add_dependency(%q<cgi>.freeze, [">= 0.1.0", "< 1.0.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
  end
end
