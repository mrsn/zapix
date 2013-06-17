# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zapix/version'

Gem::Specification.new do |spec|
  spec.name          = "zapix"
  spec.version       = Zapix::VERSION
  spec.authors       = ["stoyan"]
  spec.email         = ["stoyanov@adesso-mobile.de"]
  spec.description   = %q{Communication with the Zabbix API made easy}
  spec.summary       = %q{A cool gem}
  spec.homepage      = "https://github.com/mrsn/zapix"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "json"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "activerecord"

end
