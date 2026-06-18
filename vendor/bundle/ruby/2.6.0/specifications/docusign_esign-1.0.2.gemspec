# -*- encoding: utf-8 -*-
# stub: docusign_esign 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "docusign_esign".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["DocuSign".freeze]
  s.date = "2018-10-22"
  s.description = "The DocuSign package makes integrating DocuSign into your apps and websites a super fast and painless process. The library is open sourced on GitHub, look for the docusign-ruby-client repository. Join the eSign revolution!".freeze
  s.email = ["devcenter@docusign.com".freeze]
  s.homepage = "https://github.com/docusign/docusign-ruby-client".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "DocuSign REST API Ruby Gem".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jwt>.freeze, ["~> 1.0", ">= 1.5.2"])
      s.add_runtime_dependency(%q<typhoeus>.freeze, ["~> 1.0", ">= 1.0.1"])
      s.add_runtime_dependency(%q<json>.freeze, ["~> 2.1", ">= 2.1.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4", ">= 3.4.0"])
      s.add_development_dependency(%q<vcr>.freeze, ["~> 3.0", ">= 3.0.1"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 1.24", ">= 1.24.3"])
      s.add_development_dependency(%q<autotest>.freeze, ["~> 4.4", ">= 4.4.6"])
      s.add_development_dependency(%q<autotest-rails-pure>.freeze, ["~> 4.1", ">= 4.1.2"])
      s.add_development_dependency(%q<autotest-growl>.freeze, ["~> 0.2", ">= 0.2.16"])
      s.add_development_dependency(%q<autotest-fsevent>.freeze, ["~> 0.2", ">= 0.2.11"])
    else
      s.add_dependency(%q<jwt>.freeze, ["~> 1.0", ">= 1.5.2"])
      s.add_dependency(%q<typhoeus>.freeze, ["~> 1.0", ">= 1.0.1"])
      s.add_dependency(%q<json>.freeze, ["~> 2.1", ">= 2.1.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.4", ">= 3.4.0"])
      s.add_dependency(%q<vcr>.freeze, ["~> 3.0", ">= 3.0.1"])
      s.add_dependency(%q<webmock>.freeze, ["~> 1.24", ">= 1.24.3"])
      s.add_dependency(%q<autotest>.freeze, ["~> 4.4", ">= 4.4.6"])
      s.add_dependency(%q<autotest-rails-pure>.freeze, ["~> 4.1", ">= 4.1.2"])
      s.add_dependency(%q<autotest-growl>.freeze, ["~> 0.2", ">= 0.2.16"])
      s.add_dependency(%q<autotest-fsevent>.freeze, ["~> 0.2", ">= 0.2.11"])
    end
  else
    s.add_dependency(%q<jwt>.freeze, ["~> 1.0", ">= 1.5.2"])
    s.add_dependency(%q<typhoeus>.freeze, ["~> 1.0", ">= 1.0.1"])
    s.add_dependency(%q<json>.freeze, ["~> 2.1", ">= 2.1.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.4", ">= 3.4.0"])
    s.add_dependency(%q<vcr>.freeze, ["~> 3.0", ">= 3.0.1"])
    s.add_dependency(%q<webmock>.freeze, ["~> 1.24", ">= 1.24.3"])
    s.add_dependency(%q<autotest>.freeze, ["~> 4.4", ">= 4.4.6"])
    s.add_dependency(%q<autotest-rails-pure>.freeze, ["~> 4.1", ">= 4.1.2"])
    s.add_dependency(%q<autotest-growl>.freeze, ["~> 0.2", ">= 0.2.16"])
    s.add_dependency(%q<autotest-fsevent>.freeze, ["~> 0.2", ">= 0.2.11"])
  end
end
