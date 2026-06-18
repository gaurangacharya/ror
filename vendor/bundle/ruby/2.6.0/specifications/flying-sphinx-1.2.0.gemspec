# -*- encoding: utf-8 -*-
# stub: flying-sphinx 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "flying-sphinx".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pat Allan".freeze]
  s.date = "2014-03-30"
  s.description = "Hooks Thinking Sphinx into the Flying Sphinx service".freeze
  s.email = "pat@freelancing-gods.com".freeze
  s.executables = ["flying-sphinx".freeze]
  s.extra_rdoc_files = ["README.textile".freeze]
  s.files = ["README.textile".freeze, "bin/flying-sphinx".freeze]
  s.homepage = "https://flying-sphinx.com".freeze
  s.post_install_message = "If you're upgrading, you should rebuild your Sphinx setup when deploying:\n\n  $ heroku rake fs:rebuild\n".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Sphinx in the Cloud".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thinking-sphinx>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<riddle>.freeze, [">= 1.5.6"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.3.0"])
      s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.9"])
      s.add_runtime_dependency(%q<pusher-client>.freeze, ["~> 0.3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 0.9.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.11"])
      s.add_development_dependency(%q<rspec-fire>.freeze, ["~> 1.1.0"])
      s.add_development_dependency(%q<yajl-ruby>.freeze, ["~> 0.8.2"])
      s.add_development_dependency(%q<fakeweb>.freeze, ["~> 1.3.0"])
      s.add_development_dependency(%q<fakeweb-matcher>.freeze, ["~> 1.2.2"])
    else
      s.add_dependency(%q<thinking-sphinx>.freeze, [">= 0"])
      s.add_dependency(%q<riddle>.freeze, [">= 1.5.6"])
      s.add_dependency(%q<multi_json>.freeze, [">= 1.3.0"])
      s.add_dependency(%q<faraday>.freeze, [">= 0.9"])
      s.add_dependency(%q<pusher-client>.freeze, ["~> 0.3"])
      s.add_dependency(%q<rake>.freeze, ["~> 0.9.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.11"])
      s.add_dependency(%q<rspec-fire>.freeze, ["~> 1.1.0"])
      s.add_dependency(%q<yajl-ruby>.freeze, ["~> 0.8.2"])
      s.add_dependency(%q<fakeweb>.freeze, ["~> 1.3.0"])
      s.add_dependency(%q<fakeweb-matcher>.freeze, ["~> 1.2.2"])
    end
  else
    s.add_dependency(%q<thinking-sphinx>.freeze, [">= 0"])
    s.add_dependency(%q<riddle>.freeze, [">= 1.5.6"])
    s.add_dependency(%q<multi_json>.freeze, [">= 1.3.0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0.9"])
    s.add_dependency(%q<pusher-client>.freeze, ["~> 0.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 0.9.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.11"])
    s.add_dependency(%q<rspec-fire>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<yajl-ruby>.freeze, ["~> 0.8.2"])
    s.add_dependency(%q<fakeweb>.freeze, ["~> 1.3.0"])
    s.add_dependency(%q<fakeweb-matcher>.freeze, ["~> 1.2.2"])
  end
end
