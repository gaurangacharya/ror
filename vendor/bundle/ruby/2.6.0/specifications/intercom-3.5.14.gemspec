# -*- encoding: utf-8 -*-
# stub: intercom 3.5.14 ruby lib

Gem::Specification.new do |s|
  s.name = "intercom".freeze
  s.version = "3.5.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben McRedmond".freeze, "Ciaran Lee".freeze, "Darragh Curran".freeze, "Jeff Gardner".freeze, "Kyle Daigle".freeze, "Declan McGrath".freeze, "Jamie Osler".freeze, "Bob Long".freeze]
  s.date = "2017-05-19"
  s.description = "Intercom (https://www.intercom.io) is a customer relationship management and messaging tool for web app owners. This library wraps the api provided by Intercom. See http://docs.intercom.io/api for more details. ".freeze
  s.email = ["ben@intercom.io".freeze, "ciaran@intercom.io".freeze, "darragh@intercom.io".freeze, "jeff@intercom.io".freeze, "kyle@digitalworkbox.com".freeze, "declan@intercom.io".freeze, "jamie@intercom.io".freeze, "bob@intercom.io".freeze]
  s.homepage = "https://www.intercom.io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Ruby bindings for the Intercom API".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.4"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.3"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<fakeweb>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<json>.freeze, [">= 1.8"])
      s.add_development_dependency(%q<gem-release>.freeze, [">= 0"])
    else
      s.add_dependency(%q<minitest>.freeze, ["~> 5.4"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.3"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.0"])
      s.add_dependency(%q<fakeweb>.freeze, ["~> 1.3"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<json>.freeze, [">= 1.8"])
      s.add_dependency(%q<gem-release>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<minitest>.freeze, ["~> 5.4"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.3"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.0"])
    s.add_dependency(%q<fakeweb>.freeze, ["~> 1.3"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 1.8"])
    s.add_dependency(%q<gem-release>.freeze, [">= 0"])
  end
end
