lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'configcat/version'

Gem::Specification.new do |spec|
  spec.name          = 'configcat'
  spec.version       = ConfigCat::VERSION
  spec.authors       = ['ConfigCat']
  spec.email         = ["developer@configcat.com"]
  spec.licenses      = ["MIT"]

  spec.summary       = "ConfigCat SDK for Ruby."
  spec.description   = "ConfigCat is a configuration as a service that lets you manage your features and configurations without actually deploying new code."

  spec.homepage      = "https://configcat.com"

  spec.files         = Dir['lib/*'] + Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]
  spec.required_ruby_version = "~> 2.2"

  spec.add_dependency "concurrent-ruby"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake"
end