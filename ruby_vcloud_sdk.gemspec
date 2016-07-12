# -*- encoding: utf-8 -*-
# Copyright (c) 2009-2012 VMware, Inc.
#Copyright 2016-2016, vCloud Driver Project, CSUC 

Gem::Specification.new do |s|
  s.name         = "vcloudSDK"
  s.version      = "0.7.4"
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
  s.add_dependency "rest-client", ">= 1.6.7"
  s.add_dependency "nokogiri", ">= 1.5.6"
  s.add_dependency "netaddr"
end
