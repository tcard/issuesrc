# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'issuesrc/version'

Gem::Specification.new do |spec|
  spec.name          = "issuesrc"
  spec.version       = Issuesrc::VERSION
  spec.authors       = ["Toni Cárdenas"]
  spec.email         = ["toni@tcardenas.me"]
  spec.summary       = %q{Synchronize in-source commented tasks with your issue tracker.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/tcard/issuesrc"
  spec.license       = "GPLv2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "redcarpet"

  spec.required_ruby_version = '~> 1.9.3'
end
