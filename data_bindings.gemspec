# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "data_bindings/version"

Gem::Specification.new do |s|
  s.name        = "data_bindings"
  s.version     = DataBindings::VERSION
  s.authors     = ["Joshual Hull", "Benjamin Coe"]
  s.email       = ["joshbuddy@gmail.com"]
  s.homepage    = "http://github.com/joshbuddy/data_bindings"
  s.summary     = %q{Bind data to and from things}
  s.description = %q{Bind data to and from things.}

  s.rubyforge_project = "data_bindings"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_runtime_dependency 'hashie', '= 2.0.0.beta' NOTE: re-add after this is really published

  # specify any dependencies here; for example:
  s.add_development_dependency 'bson'
  s.add_development_dependency 'multi_json'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'builder'
  s.add_development_dependency 'httparty'
  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "tnetstring"
end
