require 'configcat'
require 'coveralls'
require 'webmock/rspec'
WebMock.allow_net_connect!
ConfigCat.logger.level = Logger::WARN
Coveralls.wear!
