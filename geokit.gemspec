# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "geokit/version"

Gem::Specification.new do |s|
  s.name        = "steveh-geokit"
  s.version     = Geokit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andre Lewis", "Bill Eisenhauer", "Steve Hoeksema"]
  s.email       = ["andre@earthcode.com", "bill_eisenhauer@yahoo.com", "steve@seven.net.nz"]
  s.homepage    = "https://github.com/steveh/geokit"
  s.summary     = "Geokit provides geocoding and distance/heading calculations."

  s.rubyforge_project = "steveh-geokit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("activesupport", ["~> 3"])

  s.add_development_dependency("mocha", [">= 0.9"])
end