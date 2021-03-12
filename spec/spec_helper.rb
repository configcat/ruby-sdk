require 'configcat'
require 'simplecov'
require 'codecov'
require 'webmock/rspec'
WebMock.allow_net_connect!
ConfigCat.logger.level = Logger::WARN
SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::Codecov
