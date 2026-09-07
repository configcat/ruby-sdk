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
  spec.description   = "Feature Flags created by developers for developers with ❤️. ConfigCat lets you manage feature flags across frontend, backend, mobile, and desktop apps without (re)deploying code. % rollouts, user targeting, segmentation. Feature toggle SDKs for all main languages. Alternative to LaunchDarkly. Host yourself, or use the hosted management app at https://configcat.com."

  spec.homepage      = "https://configcat.com"
  spec.files         = Dir['lib/*'] + Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "semantic", "~> 1.6"
  spec.add_development_dependency "rspec", "~> 3.13.0"
  spec.add_development_dependency "rake", "~> 13.4.0"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1.0"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.6')
    spec.add_development_dependency "webmock", "= 3.25.0"
  else
    spec.add_development_dependency "webmock", "~> 3.26"
  end
  spec.add_development_dependency "rubocop", "~> 1.28.2"
end
