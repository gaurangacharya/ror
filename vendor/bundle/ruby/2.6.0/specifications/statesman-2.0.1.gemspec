# -*- encoding: utf-8 -*-
# stub: statesman 2.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "statesman".freeze
  s.version = "2.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Harry Marr".freeze, "Andy Appleton".freeze]
  s.date = "2016-03-29"
  s.description = "A statesmanlike state machine library".freeze
  s.email = ["developers@gocardless.com".freeze]
  s.homepage = "https://github.com/gocardless/statesman".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A statesmanlike state machine library".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<guard-rspec>.freeze, ["~> 4.3"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.30.0"])
      s.add_development_dependency(%q<guard-rubocop>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rails>.freeze, [">= 3.2"])
      s.add_development_dependency(%q<pg>.freeze, ["~> 0.18"])
      s.add_development_dependency(%q<mysql2>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<ammeter>.freeze, ["~> 1.1"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.1"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.1"])
      s.add_dependency(%q<rspec-its>.freeze, ["~> 1.1"])
      s.add_dependency(%q<guard-rspec>.freeze, ["~> 4.3"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.30.0"])
      s.add_dependency(%q<guard-rubocop>.freeze, ["~> 1.2"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rails>.freeze, [">= 3.2"])
      s.add_dependency(%q<pg>.freeze, ["~> 0.18"])
      s.add_dependency(%q<mysql2>.freeze, ["~> 0.4"])
      s.add_dependency(%q<ammeter>.freeze, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rspec-its>.freeze, ["~> 1.1"])
    s.add_dependency(%q<guard-rspec>.freeze, ["~> 4.3"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.30.0"])
    s.add_dependency(%q<guard-rubocop>.freeze, ["~> 1.2"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rails>.freeze, [">= 3.2"])
    s.add_dependency(%q<pg>.freeze, ["~> 0.18"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.4"])
    s.add_dependency(%q<ammeter>.freeze, ["~> 1.1"])
  end
end
