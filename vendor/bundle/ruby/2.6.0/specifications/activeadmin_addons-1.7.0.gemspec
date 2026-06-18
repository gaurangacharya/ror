# -*- encoding: utf-8 -*-
# stub: activeadmin_addons 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activeadmin_addons".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Platanus".freeze, "Julio Garc\u00EDa".freeze, "Emilio Blanco".freeze, "Leandro Segovia".freeze]
  s.date = "2018-12-27"
  s.description = "Set of addons to help with the activeadmin ui".freeze
  s.email = ["rubygems@platan.us".freeze, "julioggonz@gmail.com".freeze, "emilioeduardob@gmail.com".freeze, "ldlsegovia@gmail.com".freeze]
  s.homepage = "https://github.com/platanus/activeadmin_addons".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Set of addons to help with the activeadmin ui".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<sass>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<select2-rails>.freeze, ["~> 4.0"])
      s.add_runtime_dependency(%q<xdan-datetimepicker-rails>.freeze, ["~> 2.5.1"])
      s.add_runtime_dependency(%q<require_all>.freeze, ["~> 1.5"])
      s.add_runtime_dependency(%q<active_material>.freeze, [">= 0"])
      s.add_development_dependency(%q<rails>.freeze, ["~> 4.2"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<sass-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<enumerize>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<paperclip>.freeze, [">= 0"])
      s.add_development_dependency(%q<aasm>.freeze, [">= 0"])
      s.add_development_dependency(%q<chromedriver-helper>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<factory_bot_rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<shoulda-matchers>.freeze, [">= 0"])
      s.add_development_dependency(%q<guard>.freeze, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<capybara-selenium>.freeze, [">= 0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 0"])
      s.add_dependency(%q<sass>.freeze, [">= 0"])
      s.add_dependency(%q<select2-rails>.freeze, ["~> 4.0"])
      s.add_dependency(%q<xdan-datetimepicker-rails>.freeze, ["~> 2.5.1"])
      s.add_dependency(%q<require_all>.freeze, ["~> 1.5"])
      s.add_dependency(%q<active_material>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, ["~> 4.2"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<sass-rails>.freeze, [">= 0"])
      s.add_dependency(%q<enumerize>.freeze, ["~> 2.0"])
      s.add_dependency(%q<paperclip>.freeze, [">= 0"])
      s.add_dependency(%q<aasm>.freeze, [">= 0"])
      s.add_dependency(%q<chromedriver-helper>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
      s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
      s.add_dependency(%q<factory_bot_rails>.freeze, [">= 0"])
      s.add_dependency(%q<shoulda-matchers>.freeze, [">= 0"])
      s.add_dependency(%q<guard>.freeze, [">= 0"])
      s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
      s.add_dependency(%q<capybara-selenium>.freeze, [">= 0"])
      s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 0"])
    s.add_dependency(%q<sass>.freeze, [">= 0"])
    s.add_dependency(%q<select2-rails>.freeze, ["~> 4.0"])
    s.add_dependency(%q<xdan-datetimepicker-rails>.freeze, ["~> 2.5.1"])
    s.add_dependency(%q<require_all>.freeze, ["~> 1.5"])
    s.add_dependency(%q<active_material>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, ["~> 4.2"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<sass-rails>.freeze, [">= 0"])
    s.add_dependency(%q<enumerize>.freeze, ["~> 2.0"])
    s.add_dependency(%q<paperclip>.freeze, [">= 0"])
    s.add_dependency(%q<aasm>.freeze, [">= 0"])
    s.add_dependency(%q<chromedriver-helper>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
    s.add_dependency(%q<factory_bot_rails>.freeze, [">= 0"])
    s.add_dependency(%q<shoulda-matchers>.freeze, [">= 0"])
    s.add_dependency(%q<guard>.freeze, [">= 0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<capybara-selenium>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
  end
end
