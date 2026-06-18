# -*- encoding: utf-8 -*-
# stub: rails-jquery-autocomplete 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "rails-jquery-autocomplete".freeze
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Padilla".freeze, "Joiey Seeley".freeze, "Sundus Yousuf".freeze]
  s.date = "2018-11-07"
  s.description = "Use jQuery's autocomplete plugin with Rails 4+.".freeze
  s.email = "david@padilla.cc joiey.seeley@gmail.com sundusahmedyousuf@gmail.com".freeze
  s.homepage = "https://github.com/bigtunacan/rails-jquery-autocomplete/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Use jQuery's autocomplete plugin with Rails 4+.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>.freeze, [">= 3.2"])
      s.add_development_dependency(%q<sqlite3-ruby>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<mongoid>.freeze, [">= 2.0.0"])
      s.add_development_dependency(%q<mongo_mapper>.freeze, [">= 0.9"])
      s.add_development_dependency(%q<bson_ext>.freeze, ["~> 1.6.2"])
      s.add_development_dependency(%q<guard>.freeze, [">= 0"])
      s.add_development_dependency(%q<guard-test>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit-rr>.freeze, [">= 0"])
      s.add_development_dependency(%q<shoulda>.freeze, ["~> 3.0.1"])
      s.add_development_dependency(%q<uglifier>.freeze, [">= 0"])
      s.add_development_dependency(%q<simple_form>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rails>.freeze, [">= 3.2"])
      s.add_dependency(%q<sqlite3-ruby>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<mongoid>.freeze, [">= 2.0.0"])
      s.add_dependency(%q<mongo_mapper>.freeze, [">= 0.9"])
      s.add_dependency(%q<bson_ext>.freeze, ["~> 1.6.2"])
      s.add_dependency(%q<guard>.freeze, [">= 0"])
      s.add_dependency(%q<guard-test>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit-rr>.freeze, [">= 0"])
      s.add_dependency(%q<shoulda>.freeze, ["~> 3.0.1"])
      s.add_dependency(%q<uglifier>.freeze, [">= 0"])
      s.add_dependency(%q<simple_form>.freeze, ["~> 1.5"])
      s.add_dependency(%q<byebug>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>.freeze, [">= 3.2"])
    s.add_dependency(%q<sqlite3-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<mongoid>.freeze, [">= 2.0.0"])
    s.add_dependency(%q<mongo_mapper>.freeze, [">= 0.9"])
    s.add_dependency(%q<bson_ext>.freeze, ["~> 1.6.2"])
    s.add_dependency(%q<guard>.freeze, [">= 0"])
    s.add_dependency(%q<guard-test>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit-rr>.freeze, [">= 0"])
    s.add_dependency(%q<shoulda>.freeze, ["~> 3.0.1"])
    s.add_dependency(%q<uglifier>.freeze, [">= 0"])
    s.add_dependency(%q<simple_form>.freeze, ["~> 1.5"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
  end
end
