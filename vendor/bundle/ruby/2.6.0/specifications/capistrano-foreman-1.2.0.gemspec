# -*- encoding: utf-8 -*-
# stub: capistrano-foreman 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano-foreman".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Johannes Gorset".freeze, "John Bellone".freeze]
  s.date = "2015-04-03"
  s.description = "Capistrano tasks for foreman and upstart.".freeze
  s.email = ["jgorset@gmail.com".freeze, "jbellone@bloomberg.net".freeze]
  s.homepage = "http://github.com/hyperoslo/capistrano-foreman".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Capistrano tasks for foreman and upstart.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>.freeze, ["~> 3.1"])
      s.add_runtime_dependency(%q<capistrano-bundler>.freeze, ["~> 1.1"])
    else
      s.add_dependency(%q<capistrano>.freeze, ["~> 3.1"])
      s.add_dependency(%q<capistrano-bundler>.freeze, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<capistrano>.freeze, ["~> 3.1"])
    s.add_dependency(%q<capistrano-bundler>.freeze, ["~> 1.1"])
  end
end
