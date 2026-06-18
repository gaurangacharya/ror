# -*- encoding: utf-8 -*-
# stub: spyke 6.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "spyke".freeze
  s.version = "6.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jens Balvig".freeze]
  s.date = "2022-01-29"
  s.description = "Interact with REST services in an ActiveRecord-like manner".freeze
  s.email = ["jens@balvig.com".freeze]
  s.executables = ["console".freeze]
  s.files = ["bin/console".freeze]
  s.homepage = "https://github.com/balvig/spyke".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Interact with REST services in an ActiveRecord-like manner".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0.0"])
      s.add_runtime_dependency(%q<activemodel>.freeze, [">= 4.0.0"])
      s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.9.0", "< 2.0"])
      s.add_runtime_dependency(%q<faraday_middleware>.freeze, [">= 0.9.1", "< 2.0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.5.2"])
      s.add_development_dependency(%q<actionpack>.freeze, [">= 4.0.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest-line>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov-lcov>.freeze, [">= 0"])
      s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 4.0.0"])
      s.add_dependency(%q<activemodel>.freeze, [">= 4.0.0"])
      s.add_dependency(%q<faraday>.freeze, [">= 0.9.0", "< 2.0"])
      s.add_dependency(%q<faraday_middleware>.freeze, [">= 0.9.1", "< 2.0"])
      s.add_dependency(%q<addressable>.freeze, [">= 2.5.2"])
      s.add_dependency(%q<actionpack>.freeze, [">= 4.0.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<minitest-line>.freeze, [">= 0"])
      s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov-lcov>.freeze, [">= 0"])
      s.add_dependency(%q<webmock>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.0.0"])
    s.add_dependency(%q<activemodel>.freeze, [">= 4.0.0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0.9.0", "< 2.0"])
    s.add_dependency(%q<faraday_middleware>.freeze, [">= 0.9.1", "< 2.0"])
    s.add_dependency(%q<addressable>.freeze, [">= 2.5.2"])
    s.add_dependency(%q<actionpack>.freeze, [">= 4.0.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-line>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov-lcov>.freeze, [">= 0"])
    s.add_dependency(%q<webmock>.freeze, [">= 0"])
  end
end
