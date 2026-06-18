# -*- encoding: utf-8 -*-
# stub: faraday-encoding 0.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday-encoding".freeze
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Takayuki Matsubara".freeze]
  s.date = "2016-09-19"
  s.description = "A Faraday Middleware sets body encoding when specified by server.".freeze
  s.email = ["takayuki.1229@m3.com".freeze]
  s.homepage = "".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A Faraday Middleware sets body encoding when specified by server.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<faraday_middleware>.freeze, ["~> 0.10"])
      s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<faraday_middleware>.freeze, ["~> 0.10"])
      s.add_dependency(%q<faraday>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<faraday_middleware>.freeze, ["~> 0.10"])
    s.add_dependency(%q<faraday>.freeze, [">= 0"])
  end
end
