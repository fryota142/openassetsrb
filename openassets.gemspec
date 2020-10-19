# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openassets/version'

Gem::Specification.new do |spec|
  spec.name          = "openassets"
  spec.version       = OpenAssets::VERSION
  spec.authors       = ["azuchi"]
  spec.email         = ["azuchi@chaintope.com"]

  spec.summary       = %q{The implementation of the Open Assets Protocol for Ruby.}
  spec.description   = %q{The implementation of the Open Assets Protocol for Ruby.}
  spec.homepage      = "https://github.com/chaintope/openassetsrb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "bitcoinrb", ">= 0.3.2"
  spec.add_runtime_dependency "ffi", "~>1.9.8"
  spec.add_runtime_dependency "rest-client", "2.0.2"
  spec.add_runtime_dependency "httpclient"
  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "activerecord-jdbcsqlite3-adapter"
  spec.add_runtime_dependency "leb128", '~> 1.0.0'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "travis"

end
