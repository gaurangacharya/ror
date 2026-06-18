# -*- encoding: utf-8 -*-
# stub: tzwhere 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "tzwhere".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Daniels".freeze]
  s.date = "2014-03-03"
  s.email = ["adam@mediadrive.ca".freeze]
  s.homepage = "http://github.com/adam12/tzwhere".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Time zone lookup by latitude/longitude using nearest neighbor implementation.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<kdtree>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<kdtree>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<kdtree>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
