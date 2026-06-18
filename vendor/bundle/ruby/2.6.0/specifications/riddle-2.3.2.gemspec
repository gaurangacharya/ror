# -*- encoding: utf-8 -*-
# stub: riddle 2.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "riddle".freeze
  s.version = "2.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pat Allan".freeze]
  s.date = "2018-09-23"
  s.description = "A Ruby API and configuration helper for the Sphinx search service.".freeze
  s.email = ["pat@freelancing-gods.com".freeze]
  s.homepage = "http://pat.github.io/riddle/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "An API for Sphinx, written in and for Ruby.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 2.5.0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0.7.2"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0.9.2"])
      s.add_dependency(%q<rspec>.freeze, [">= 2.5.0"])
      s.add_dependency(%q<yard>.freeze, [">= 0.7.2"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0.9.2"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.5.0"])
    s.add_dependency(%q<yard>.freeze, [">= 0.7.2"])
  end
end
