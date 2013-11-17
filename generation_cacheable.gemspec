# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gen_cache/version"

Gem::Specification.new do |s|
  s.name        = "generation_cacheable"
  s.version     = GenerationCacheable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pat McGee"]
  s.email       = ["patmcgee331@gmail.com"]
  s.homepage    = "https://github.com/pathouse/generation-cacheable"
  s.summary     = %q{a simple cache implementation with attribute based expiry}
  s.description = %q{a simple cache implementation with attribute based expiry}

  s.add_dependency("rails", ">= 3.0.0")
  s.add_development_dependency("rspec", "2.8")
  s.add_development_dependency("mocha", "0.10.5")
  s.add_development_dependancy("cityhash", "0.8.1")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
