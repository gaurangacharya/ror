# -*- encoding: utf-8 -*-
# stub: joiner 0.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "joiner".freeze
  s.version = "0.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pat Allan".freeze]
  s.date = "2018-08-18"
  s.description = "Builds ActiveRecord outer joins from association paths and provides references to table aliases.".freeze
  s.email = ["pat@freelancing-gods.com".freeze]
  s.homepage = "https://github.com/pat/joiner".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Builds ActiveRecord joins from association paths".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2.beta1"])
      s.add_development_dependency(%q<combustion>.freeze, ["~> 0.8"])
      s.add_development_dependency(%q<rails>.freeze, [">= 5.2.0"])
      s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3"])
      s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3.8"])
    else
      s.add_dependency(%q<activerecord>.freeze, [">= 5.2.beta1"])
      s.add_dependency(%q<combustion>.freeze, ["~> 0.8"])
      s.add_dependency(%q<rails>.freeze, [">= 5.2.0"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 3"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3.8"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 5.2.beta1"])
    s.add_dependency(%q<combustion>.freeze, ["~> 0.8"])
    s.add_dependency(%q<rails>.freeze, [">= 5.2.0"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 3"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3.8"])
  end
end
