# -*- encoding: utf-8 -*-
# Copyright (c) 2009-2012 VMware, Inc.

Gem::Specification.new do |s|
  s.name         = "ruby_vcloud_sdk"
  s.version      = "0.7.1"
  s.platform     = Gem::Platform::RUBY
  s.summary      = "BOSH vCloud API client"
  s.description  = "BOSH vCloud API client\n#{`git rev-parse HEAD`[0, 6]}"
  s.author       = "VMware"
  s.homepage     = 'https://github.com/vchs/ruby_vcloud_sdk'
  s.license      = 'Apache 2.0'
  s.email        = "support@cloudfoundry.com"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.files        = `git ls-files -- lib/*`.split("\n") + %w(README.md)
  s.require_path = "lib"

  s.add_dependency "builder", "~>3.1.4"
  s.add_dependency "httpclient", "~>2.4.0"
  s.add_dependency "rest-client", "~>1.6.7"
  s.add_dependency "nokogiri", ">=1.5.6"
  s.add_dependency "netaddr"
end
