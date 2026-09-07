if ENV['COV'] == 'true'
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start do
    track_files 'lib/**/*.rb'
  end
end

require 'configcat'
require 'webmock/rspec'
WebMock.allow_net_connect!
ConfigCat.logger.level = Logger::WARN
