# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{stella}
  s.version = "0.8.7.001"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2010-05-21}
  s.default_executable = %q{stella}
  s.description = %q{Blame Stella for breaking your web application!}
  s.email = %q{delano@solutious.com}
  s.executables = ["stella"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.md"
  ]
  s.files = [
    ".gitignore",
     ".gitmodules",
     "CHANGES.txt",
     "LICENSE.txt",
     "README.md",
     "Rakefile",
     "Rudyfile",
     "VERSION.yml",
     "bin/stella",
     "examples/cookies/plan.rb",
     "examples/csvdata/plan.rb",
     "examples/csvdata/search_terms.csv",
     "examples/dynamic/plan.rb",
     "examples/essentials/logo.png",
     "examples/essentials/plan.rb",
     "examples/essentials/search_terms.txt",
     "examples/exceptions/plan.rb",
     "examples/timeout/plan.rb",
     "examples/variables/plan.rb",
     "lib/stella.rb",
     "lib/stella/cli.rb",
     "lib/stella/client.rb",
     "lib/stella/client/container.rb",
     "lib/stella/common.rb",
     "lib/stella/data.rb",
     "lib/stella/data/http.rb",
     "lib/stella/engine.rb",
     "lib/stella/engine/functional.rb",
     "lib/stella/engine/load.rb",
     "lib/stella/guidelines.rb",
     "lib/stella/logger.rb",
     "lib/stella/testplan.rb",
     "lib/stella/utils.rb",
     "lib/stella/utils/httputil.rb",
     "stella.gemspec",
     "support/sample_webapp/app.rb",
     "support/sample_webapp/config.ru",
     "support/useragents.txt",
     "tryouts/01_numeric_mixins_tryouts.rb",
     "tryouts/12_digest_tryouts.rb",
     "tryouts/70_module_usage.rb",
     "tryouts/api/10_functional.rb",
     "tryouts/configs/failed_requests.rb",
     "tryouts/configs/global_sequential.rb",
     "tryouts/proofs/thread_queue.rb",
     "vendor/httpclient-2.1.5.2/httpclient.rb",
     "vendor/httpclient-2.1.5.2/httpclient/auth.rb",
     "vendor/httpclient-2.1.5.2/httpclient/cacert.p7s",
     "vendor/httpclient-2.1.5.2/httpclient/cacert_sha1.p7s",
     "vendor/httpclient-2.1.5.2/httpclient/connection.rb",
     "vendor/httpclient-2.1.5.2/httpclient/cookie.rb",
     "vendor/httpclient-2.1.5.2/httpclient/http.rb",
     "vendor/httpclient-2.1.5.2/httpclient/session.rb",
     "vendor/httpclient-2.1.5.2/httpclient/ssl_config.rb",
     "vendor/httpclient-2.1.5.2/httpclient/timeout.rb",
     "vendor/httpclient-2.1.5.2/httpclient/util.rb"
  ]
  s.homepage = %q{http://blamestella.com/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{stella}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Blame Stella for breaking your web application!}
  s.test_files = [
    "examples/cookies/plan.rb",
     "examples/csvdata/plan.rb",
     "examples/dynamic/plan.rb",
     "examples/essentials/plan.rb",
     "examples/exceptions/plan.rb",
     "examples/timeout/plan.rb",
     "examples/variables/plan.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<gibbler>, [">= 0.8.1"])
      s.add_runtime_dependency(%q<drydock>, [">= 0.6.9"])
      s.add_runtime_dependency(%q<benelux>, [">= 0.5.15"])
      s.add_runtime_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_runtime_dependency(%q<storable>, [">= 0.7.3"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
    else
      s.add_dependency(%q<gibbler>, [">= 0.8.1"])
      s.add_dependency(%q<drydock>, [">= 0.6.9"])
      s.add_dependency(%q<benelux>, [">= 0.5.15"])
      s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
      s.add_dependency(%q<storable>, [">= 0.7.3"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
    end
  else
    s.add_dependency(%q<gibbler>, [">= 0.8.1"])
    s.add_dependency(%q<drydock>, [">= 0.6.9"])
    s.add_dependency(%q<benelux>, [">= 0.5.15"])
    s.add_dependency(%q<sysinfo>, [">= 0.7.3"])
    s.add_dependency(%q<storable>, [">= 0.7.3"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
  end
end

