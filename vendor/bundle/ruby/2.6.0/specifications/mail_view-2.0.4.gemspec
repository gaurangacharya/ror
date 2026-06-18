# -*- encoding: utf-8 -*-
# stub: mail_view 2.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "mail_view".freeze
  s.version = "2.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Peek".freeze]
  s.date = "2013-12-13"
  s.email = "josh@joshpeek.com".freeze
  s.homepage = "https://github.com/37signals/mail_view".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Visual email testing".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tilt>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_development_dependency(%q<mail>.freeze, ["~> 2.2"])
      s.add_development_dependency(%q<tmail>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<tilt>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_dependency(%q<mail>.freeze, ["~> 2.2"])
      s.add_dependency(%q<tmail>.freeze, ["~> 1.2"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<tilt>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    s.add_dependency(%q<mail>.freeze, ["~> 2.2"])
    s.add_dependency(%q<tmail>.freeze, ["~> 1.2"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
