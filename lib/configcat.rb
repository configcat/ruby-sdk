require 'configcat/interfaces'
require 'configcat/localdictionarydatasource'
require 'configcat/localfiledatasource'
require 'configcat/configcatclient'
require 'configcat/user'
require 'logger'

module ConfigCat
  @logger = Logger.new(STDOUT, level: Logger::WARN)
  class << self
    attr_accessor :logger
  end

  # Creates a new or gets an already existing `ConfigCatClient` for the given `sdk_key`.
  #
  # :param sdk_key [String] ConfigCat SDK Key to access your configuration.
  # :param options [ConfigCatOptions] Configuration `ConfigCatOptions` for `ConfigCatClient`.
  # :return [ConfigCatClient] the `ConfigCatClient` instance.
  def ConfigCat.get(sdk_key, options = nil)
    return ConfigCatClient.get(sdk_key, options)
  end

  # Closes all ConfigCatClient instances.
  def ConfigCat.close_all
    ConfigCatClient.close_all
  end
end
