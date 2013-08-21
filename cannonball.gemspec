# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cannonball/version'

Gem::Specification.new do |spec|
  spec.name          = "cannonball"
  spec.version       = Cannonball::VERSION
  spec.authors       = ["Marca Tatem"]
  spec.email         = ["marca.tatem@gmail.com"]
  spec.summary       = %q{URL normalization and canonicalization}
  spec.description   = spec.summary
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable",      "~> 2.3.4"
  spec.add_dependency "public_suffix",    "~> 1.3.0"
  spec.add_dependency "ethon",            "~> 0.5.12"
  spec.add_dependency "redis",            "~> 3.0.4"
  spec.add_dependency "redis-namespace",  "~> 1.3.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.6"
  spec.add_development_dependency "ruby-prof"
end
