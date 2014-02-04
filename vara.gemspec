# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vara/version'

Gem::Specification.new do |spec|
  spec.name          = "vara"
  spec.version       = Vara::VERSION
  spec.authors       = ["CF London"]
  spec.email         = ["cf-london@pivotallabs.com"]
  spec.description   = %q{Write a gem description}
  spec.summary       = %q{Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "bosh_cli"
  spec.add_dependency "erubis"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.99.0.beta1"
  spec.add_development_dependency "rubocop", "~> 0.18.1"
end
