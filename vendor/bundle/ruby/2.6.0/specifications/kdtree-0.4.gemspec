# -*- encoding: utf-8 -*-
# stub: kdtree 0.4 ruby lib
# stub: ext/kdtree/extconf.rb

Gem::Specification.new do |s|
  s.name = "kdtree".freeze
  s.version = "0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Doppelt".freeze]
  s.date = "2017-03-28"
  s.description = "A kdtree is a data structure that makes it possible to quickly solve\nthe nearest neighbor problem. This is a native 2d kdtree suitable for\nproduction use with millions of points.\n".freeze
  s.email = ["amd@gurge.com".freeze]
  s.extensions = ["ext/kdtree/extconf.rb".freeze]
  s.files = ["ext/kdtree/extconf.rb".freeze]
  s.homepage = "http://github.com/gurgeous/kdtree".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Blazingly fast, native 2d kdtree.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
      s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
      s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.0"])
  end
end
