# -*- encoding: utf-8 -*-
# stub: zeus 0.15.13 ruby lib

Gem::Specification.new do |s|
  s.name = "zeus".freeze
  s.version = "0.15.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Burke Libbey".freeze]
  s.date = "2017-02-06"
  s.description = "Boot any rails app in under a second".freeze
  s.email = ["burke@libbey.me".freeze]
  s.executables = ["zeus".freeze]
  s.files = ["bin/zeus".freeze]
  s.homepage = "https://github.com/burke/zeus".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Zeus is an intelligent preloader for ruby applications. It allows normal development tasks to be run in a fraction of a second.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<method_source>.freeze, [">= 0.6.7"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6"])
    else
      s.add_dependency(%q<method_source>.freeze, [">= 0.6.7"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
    end
  else
    s.add_dependency(%q<method_source>.freeze, [">= 0.6.7"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
  end
end
