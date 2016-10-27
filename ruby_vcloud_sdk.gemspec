# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name         = "ruby_vcloud_sdk"
  s.version      = "0.7.7"
  s.date         = Date.today.to_s
  s.platform     = Gem::Platform::RUBY
  s.summary      = "BOSH vCloud API client"
  s.description  = "BOSH vCloud API client\n#{`git rev-parse HEAD`[0, 6]}"
  s.author       = "CSUC"
  s.homepage     = 'https://www.csuc.cat'
  s.license      = 'Apache 2.0'
  s.email        = "ois@csuc.cat"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.files        = `git ls-files -- lib/*`.split("\n") + %w(README.md)
  s.require_path = "lib"

  s.add_dependency "builder", ">= 3.1"
  s.add_dependency "httpclient", ">= 2.4.0"
  s.add_dependency "rest-client", "<= 1.8.0"
  s.add_dependency "nokogiri", ">= 1.5.6"
  s.add_dependency "netaddr"
end
