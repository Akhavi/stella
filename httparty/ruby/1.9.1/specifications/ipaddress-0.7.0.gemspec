# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ipaddress}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marco Ceresa"]
  s.date = %q{2010-09-07}
  s.description = %q{      IPAddress is a Ruby library designed to make manipulation 
      of IPv4 and IPv6 addresses both powerful and simple. It mantains
      a layer of compatibility with Ruby's own IPAddr, while 
      addressing many of its issues.
}
  s.email = %q{ceresa@gmail.com}
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = [".document", ".gitignore", "CHANGELOG.rdoc", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "lib/ipaddress.rb", "lib/ipaddress/extensions/extensions.rb", "lib/ipaddress/ipv4.rb", "lib/ipaddress/ipv6.rb", "lib/ipaddress/prefix.rb", "test/ipaddress/extensions/extensions_test.rb", "test/ipaddress/ipv4_test.rb", "test/ipaddress/ipv6_test.rb", "test/ipaddress/prefix_test.rb", "test/ipaddress_test.rb", "test/test_helper.rb"]
  s.homepage = %q{http://github.com/bluemonk/ipaddress}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{IPv4/IPv6 addresses manipulation library}
  s.test_files = ["test/test_helper.rb", "test/ipaddress_test.rb", "test/ipaddress/prefix_test.rb", "test/ipaddress/ipv6_test.rb", "test/ipaddress/extensions/extensions_test.rb", "test/ipaddress/ipv4_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
