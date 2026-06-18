# -*- encoding: utf-8 -*-
# stub: delayed_paperclip 3.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "delayed_paperclip".freeze
  s.version = "3.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jesse Storimer".freeze, "Bert Goethals".freeze, "James Gifford".freeze, "Scott Carleton".freeze]
  s.date = "2016-08-26"
  s.description = "Process your Paperclip attachments in the background with ActiveJob".freeze
  s.email = ["james@jamesrgifford.com".freeze, "scott@artsicle.com".freeze]
  s.homepage = "https://github.com/jrgifford/delayed_paperclip".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Process your Paperclip attachments in the background".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<paperclip>.freeze, [">= 3.3"])
      s.add_runtime_dependency(%q<activejob>.freeze, [">= 4.2"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["< 3.0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.5.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_development_dependency(%q<railties>.freeze, [">= 0"])
    else
      s.add_dependency(%q<paperclip>.freeze, [">= 3.3"])
      s.add_dependency(%q<activejob>.freeze, [">= 4.2"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["< 3.0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.5.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_dependency(%q<railties>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<paperclip>.freeze, [">= 3.3"])
    s.add_dependency(%q<activejob>.freeze, [">= 4.2"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["< 3.0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<appraisal>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.5.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<railties>.freeze, [">= 0"])
  end
end
