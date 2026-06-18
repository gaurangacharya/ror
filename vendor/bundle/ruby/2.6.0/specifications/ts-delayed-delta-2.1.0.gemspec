# -*- encoding: utf-8 -*-
# stub: ts-delayed-delta 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ts-delayed-delta".freeze
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pat Allan".freeze]
  s.date = "2018-03-17"
  s.description = "Manage delta indexes via Delayed Job for Thinking Sphinx".freeze
  s.email = ["pat@freelancing-gods.com".freeze]
  s.homepage = "http://github.com/pat/ts-delayed-delta".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Thinking Sphinx - Delayed Deltas".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thinking-sphinx>.freeze, [">= 1.5.0"])
      s.add_runtime_dependency(%q<delayed_job>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 2.0"])
      s.add_development_dependency(%q<appraisal>.freeze, ["~> 0.5.2"])
      s.add_development_dependency(%q<combustion>.freeze, ["~> 0.4.0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, ["~> 0.7.1"])
      s.add_development_dependency(%q<delayed_job_active_record>.freeze, ["~> 0.4.4"])
      s.add_development_dependency(%q<mysql2>.freeze, ["~> 0.3.18"])
      s.add_development_dependency(%q<pg>.freeze, ["~> 0.11.0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.11"])
    else
      s.add_dependency(%q<thinking-sphinx>.freeze, [">= 1.5.0"])
      s.add_dependency(%q<delayed_job>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 2.0"])
      s.add_dependency(%q<appraisal>.freeze, ["~> 0.5.2"])
      s.add_dependency(%q<combustion>.freeze, ["~> 0.4.0"])
      s.add_dependency(%q<database_cleaner>.freeze, ["~> 0.7.1"])
      s.add_dependency(%q<delayed_job_active_record>.freeze, ["~> 0.4.4"])
      s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.18"])
      s.add_dependency(%q<pg>.freeze, ["~> 0.11.0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.11"])
    end
  else
    s.add_dependency(%q<thinking-sphinx>.freeze, [">= 1.5.0"])
    s.add_dependency(%q<delayed_job>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 2.0"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 0.5.2"])
    s.add_dependency(%q<combustion>.freeze, ["~> 0.4.0"])
    s.add_dependency(%q<database_cleaner>.freeze, ["~> 0.7.1"])
    s.add_dependency(%q<delayed_job_active_record>.freeze, ["~> 0.4.4"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.18"])
    s.add_dependency(%q<pg>.freeze, ["~> 0.11.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.11"])
  end
end
