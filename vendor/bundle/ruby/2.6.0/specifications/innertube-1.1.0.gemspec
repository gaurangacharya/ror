# -*- encoding: utf-8 -*-
# stub: innertube 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "innertube".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sean Cribbs".freeze, "Kyle Kingsbury".freeze]
  s.date = "2013-07-29"
  s.description = "Because everyone needs their own pool library.".freeze
  s.email = ["sean@basho.com".freeze, "aphyr@aphyr.com".freeze]
  s.homepage = "http://github.com/basho/innertube".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A thread-safe resource pool, originally borne in riak-client (Ripple).".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.10.0"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 2.10.0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 2.10.0"])
  end
end
