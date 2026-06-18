# -*- encoding: utf-8 -*-
# stub: web_translate_it 2.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "web_translate_it".freeze
  s.version = "2.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Edouard Briere".freeze]
  s.date = "2016-02-03"
  s.description = "A gem to push and pull language files to WebTranslateIt.com.".freeze
  s.email = "edouard@atelierconvivialite.com".freeze
  s.executables = ["wti".freeze]
  s.extra_rdoc_files = ["history.md".freeze, "readme.md".freeze]
  s.files = ["bin/wti".freeze, "history.md".freeze, "readme.md".freeze]
  s.homepage = "https://webtranslateit.com".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "readme.md".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A CLI to sync locale files with WebTranslateIt.com.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<trollop>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 2.6.0"])
      s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
      s.add_dependency(%q<trollop>.freeze, ["~> 2.0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 2.6.0"])
      s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
    s.add_dependency(%q<trollop>.freeze, ["~> 2.0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.6.0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
  end
end
