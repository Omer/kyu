# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kyu/version'

Gem::Specification.new do |spec|
  spec.name          = "kyu"
  spec.version       = Kyu::VERSION
  spec.authors       = ["Omer Jakobinsky"]
  spec.email         = ["omer@jakobinsky.com"]
  spec.description   = %q{SQS background processing for Ruby}
  spec.summary       = %q{A simple background processing for Ruby backed by SQS}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", ">= 1.33"
  spec.add_dependency "daemons"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
