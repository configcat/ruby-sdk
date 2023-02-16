require 'configcat'
require 'webmock/rspec'
WebMock.allow_net_connect!
ConfigCat.logger.level = Logger::WARN
if ENV['COV'] == 'true'
  require 'simplecov'
  require 'codecov'
  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
