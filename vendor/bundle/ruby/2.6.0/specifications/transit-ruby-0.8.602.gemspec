# -*- encoding: utf-8 -*-
# stub: transit-ruby 0.8.602 ruby lib

Gem::Specification.new do |s|
  s.name = "transit-ruby".freeze
  s.version = "0.8.602"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Russ Olsen".freeze, "David Chelimsky".freeze, "Yoko Harada".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDfDCCAmSgAwIBAgIBATANBgkqhkiG9w0BAQUFADBCMRAwDgYDVQQDDAdhbnli\nb2R5MRkwFwYKCZImiZPyLGQBGRYJY29nbml0ZWN0MRMwEQYKCZImiZPyLGQBGRYD\nY29tMB4XDTE2MTEwNDE0Mjk1NloXDTE3MTEwNDE0Mjk1NlowQjEQMA4GA1UEAwwH\nYW55Ym9keTEZMBcGCgmSJomT8ixkARkWCWNvZ25pdGVjdDETMBEGCgmSJomT8ixk\nARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALGCPh24AveN\nZpeG2FnBrz/kVv+xhtQf4fUTQmJFwSC+3HLJ42xSRq1S5dYu+97q0+eJYErMLOfF\nUkeNNgJxaXzoFjnAX5wHCu6iFE7N5SrGxh6JsQ0Xm7EDcizadw/Fq2JqxhwnyvGV\n53QXXjfYWItEc/+lNaYVMpeaH9t5eXPptNzVl9CTzU+032o6ajsVh1IX3gb1bBp8\nRqBsG3O00XigcoWa8Tx2FeoNm54bZaCDee2/BdHFgzz2A1qi+uGnzo341ll53iZu\nj/b2mAAp++b8bAj1sYtFalac9zv+qopzKdx5YzhIfBx/5Vmiz5T9L+eIZiYvM84n\nOWLzEt5FGHECAwEAAaN9MHswCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0O\nBBYEFLy9GdRHpvfnUB0Mgh0+liT0YNIAMCAGA1UdEQQZMBeBFWFueWJvZHlAY29n\nbml0ZWN0LmNvbTAgBgNVHRIEGTAXgRVhbnlib2R5QGNvZ25pdGVjdC5jb20wDQYJ\nKoZIhvcNAQEFBQADggEBAD+zL60WUH0rRgubh+mtf0OyJZgpXADpLfTCkuB+NF9T\nQIDwUwRuewUb5S+JmlQsW6mFnsO9/39Rlo1Gr4xy+RXK98uNdtqry8Vx9e+j2clt\nMzhWcl3mN72VYu8HqSGzjVnq+YwYS4apVF5K37QARx4Zs5A7JWJHzSHpvLbmMk1v\nIG8XDU4EiNht2QAJaORxVDCtB18ZeQaP8CoHYPhRCA+/luQ7oq2XscnVDKydK/zR\na4XLsgv1cFiPv4P1gB24Dmi+d7Ma0b7gnSN9kKtHLhBD8SMlmoqWmP+UXY13LFkM\n8n0cTm+ZRH7Ytbv7+3g9RFz+BA56kbeTabhIdQeJ3jE=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2017-08-11"
  s.description = "Transit marshalling for Ruby".freeze
  s.email = ["russ@cognitect.com".freeze, "dchelimsky@cognitect.com".freeze, "yoko@cognitect.com".freeze]
  s.homepage = "http://github.com/cognitect/transit-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.10".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Transit marshalling for Ruby".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<oj>.freeze, ["~> 2.18"])
      s.add_runtime_dependency(%q<msgpack>.freeze, ["~> 1.1.0"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.8.7.4"])
      s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.1.1"])
      s.add_development_dependency(%q<yard-redcarpet-ext>.freeze, ["~> 0.0.3"])
      s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.1"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<wrong>.freeze, ["~> 0.7.1"])
    else
      s.add_dependency(%q<oj>.freeze, ["~> 2.18"])
      s.add_dependency(%q<msgpack>.freeze, ["~> 1.1.0"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.8.7.4"])
      s.add_dependency(%q<redcarpet>.freeze, ["~> 3.1.1"])
      s.add_dependency(%q<yard-redcarpet-ext>.freeze, ["~> 0.0.3"])
      s.add_dependency(%q<addressable>.freeze, ["~> 2.3"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.1"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<wrong>.freeze, ["~> 0.7.1"])
    end
  else
    s.add_dependency(%q<oj>.freeze, ["~> 2.18"])
    s.add_dependency(%q<msgpack>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.8.7.4"])
    s.add_dependency(%q<redcarpet>.freeze, ["~> 3.1.1"])
    s.add_dependency(%q<yard-redcarpet-ext>.freeze, ["~> 0.0.3"])
    s.add_dependency(%q<addressable>.freeze, ["~> 2.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<wrong>.freeze, ["~> 0.7.1"])
  end
end
