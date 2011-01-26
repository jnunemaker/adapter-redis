# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adapter/redis/version"

Gem::Specification.new do |s|
  s.name        = "adapter-redis"
  s.version     = Adapter::Redis::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Nunemaker"]
  s.email       = ["nunemaker@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Adapter for redis}
  s.description = %q{Adapter for redis}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'adapter', '~> 0.5.1'
  s.add_dependency 'redis', '~> 2.1.1'
end
