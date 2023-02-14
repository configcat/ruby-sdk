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
  def ConfigCat.get(sdk_key, options=nil)
    return ConfigCatClient.get(sdk_key, options)
  end

  # Closes all ConfigCatClient instances.
  def ConfigCat.close_all
    ConfigCatClient.close_all
  end

  def ConfigCat.create_client(sdk_key, data_governance: DataGovernance::GLOBAL)
    #
    #   Create an instance of ConfigCatClient and setup Auto Poll mode with default options
    #
    #   :param sdk_key: ConfigCat SDK Key to access your configuration.
    #   :param data_governance:
    #   Default: Global. Set this parameter to be in sync with the Data Governance preference on the Dashboard:
    #   https://app.configcat.com/organization/data-governance
    #   (Only Organization Admins have access)
    #
    return create_client_with_auto_poll(sdk_key, data_governance: data_governance)
  end

  # Create an instance of ConfigCatClient and setup Auto Poll mode with custom options
  #
  # :param sdk_key: ConfigCat SDK Key to access your configuration.
  # :param poll_interval_seconds: The client's poll interval in seconds. Default: 60 seconds.
  # :param on_configuration_changed_callback: You can subscribe to configuration changes with this callback
  # :param max_init_wait_time_seconds: maximum waiting time for first configuration fetch in polling mode.
  # :param config_cache: If you want to use custom caching instead of the client's default,
  # You can provide an implementation of ConfigCache.
  # :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
  # :param proxy_address: Proxy address
  # :param proxy_port: Proxy port
  # :param proxy_user: username for proxy authentication
  # :param proxy_pass: password for proxy authentication
  # :param open_timeout_seconds: The number of seconds to wait for the server to make the initial connection. Default: 10 seconds.
  # :param read_timeout_seconds: The number of seconds to wait for the server to respond before giving up. Default: 30 seconds.
  # :param flag_overrides: A FlagOverrides implementation used to override feature flags & settings.
  # :param data_governance:
  # Default: Global. Set this parameter to be in sync with the Data Governance preference on the Dashboard:
  # https://app.configcat.com/organization/data-governance
  # (Only Organization Admins have access)
  def ConfigCat.create_client_with_auto_poll(sdk_key,
                                             poll_interval_seconds: 60,
                                             max_init_wait_time_seconds: 5,
                                             on_configuration_changed_callback: nil,
                                             config_cache: nil,
                                             base_url: nil,
                                             proxy_address: nil,
                                             proxy_port: nil,
                                             proxy_user: nil,
                                             proxy_pass: nil,
                                             open_timeout_seconds: 10,
                                             read_timeout_seconds: 30,
                                             flag_overrides: nil,
                                             data_governance: DataGovernance::GLOBAL)
    options = ConfigCatOptions.new(
      base_url: base_url,
      polling_mode: PollingMode.auto_poll(poll_interval_seconds: poll_interval_seconds, max_init_wait_time_seconds: max_init_wait_time_seconds),
      config_cache: config_cache,
      proxy_address: proxy_address,
      proxy_port: proxy_port,
      proxy_user: proxy_user,
      proxy_pass: proxy_pass,
      open_timeout_seconds: open_timeout_seconds,
      read_timeout_seconds: read_timeout_seconds,
      flag_overrides: flag_overrides,
      data_governance: data_governance
    )
    client = ConfigCatClient.get(sdk_key, options)
    client.hooks.add_on_config_changed(on_configuration_changed_callback) if on_configuration_changed_callback
    client.log.warn('create_client_with_auto_poll is deprecated. Create the ConfigCat Client as a Singleton object with `configcatclient.get()` instead')
    return client
  end

  # Create an instance of ConfigCatClient and setup Lazy Load mode with custom options
  #
  # :param sdk_key: ConfigCat SDK Key to access your configuration.
  # :param cache_time_to_live_seconds: The cache TTL.
  # :param config_cache: If you want to use custom caching instead of the client's default,
  # You can provide an implementation of ConfigCache.
  # :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
  # :param proxy_address: Proxy address
  # :param proxy_port: Proxy port
  # :param proxy_user: username for proxy authentication
  # :param proxy_pass: password for proxy authentication
  # :param open_timeout_seconds: The number of seconds to wait for the server to make the initial connection. Default: 10 seconds.
  # :param read_timeout_seconds: The number of seconds to wait for the server to respond before giving up. Default: 30 seconds.
  # :param flag_overrides: A FlagOverrides implementation used to override feature flags & settings.
  # :param data_governance:
  # Default: Global. Set this parameter to be in sync with the Data Governance preference on the Dashboard:
  # https://app.configcat.com/organization/data-governance
  # (Only Organization Admins have access)
  def ConfigCat.create_client_with_lazy_load(sdk_key,
                                             cache_time_to_live_seconds: 60,
                                             config_cache: nil,
                                             base_url: nil,
                                             proxy_address: nil,
                                             proxy_port: nil,
                                             proxy_user: nil,
                                             proxy_pass: nil,
                                             open_timeout_seconds: 10,
                                             read_timeout_seconds: 30,
                                             flag_overrides: nil,
                                             data_governance: DataGovernance::GLOBAL)
    options = ConfigCatOptions.new(
      base_url: base_url,
      polling_mode: PollingMode.lazy_load(cache_refresh_interval_seconds: cache_time_to_live_seconds),
      config_cache: config_cache,
      proxy_address: proxy_address,
      proxy_port: proxy_port,
      proxy_user: proxy_user,
      proxy_pass: proxy_pass,
      open_timeout_seconds: open_timeout_seconds,
      read_timeout_seconds: read_timeout_seconds,
      flag_overrides: flag_overrides,
      data_governance: data_governance
    )
    client = ConfigCatClient.get(sdk_key, options)
    client.log.warn('create_client_with_lazy_load is deprecated. Create the ConfigCat Client as a Singleton object with `configcatclient.get()` instead')
    return client
  end

  # Create an instance of ConfigCatClient and setup Manual Poll mode with custom options
  #
  # :param sdk_key: ConfigCat SDK Key to access your configuration.
  # :param config_cache: If you want to use custom caching instead of the client's default,
  # You can provide an implementation of ConfigCache.
  # :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
  # :param proxy_address: Proxy address
  # :param proxy_port: Proxy port
  # :param proxy_user: username for proxy authentication
  # :param proxy_pass: password for proxy authentication
  # :param open_timeout_seconds: The number of seconds to wait for the server to make the initial connection. Default: 10 seconds.
  # :param read_timeout_seconds: The number of seconds to wait for the server to respond before giving up. Default: 30 seconds.
  # :param flag_overrides: A FlagOverrides implementation used to override feature flags & settings.
  # :param data_governance:
  # Default: Global. Set this parameter to be in sync with the Data Governance preference on the Dashboard:
  # https://app.configcat.com/organization/data-governance
  # (Only Organization Admins have access)
  def ConfigCat.create_client_with_manual_poll(sdk_key,
                                               config_cache: nil,
                                               base_url: nil,
                                               proxy_address: nil,
                                               proxy_port: nil,
                                               proxy_user: nil,
                                               proxy_pass: nil,
                                               open_timeout_seconds: 10,
                                               read_timeout_seconds: 30,
                                               flag_overrides: nil,
                                               data_governance: DataGovernance::GLOBAL)
    options = ConfigCatOptions.new(
      base_url: base_url,
      polling_mode: PollingMode.manual_poll(),
      config_cache: config_cache,
      proxy_address: proxy_address,
      proxy_port: proxy_port,
      proxy_user: proxy_user,
      proxy_pass: proxy_pass,
      open_timeout_seconds: open_timeout_seconds,
      read_timeout_seconds: read_timeout_seconds,
      flag_overrides: flag_overrides,
      data_governance: data_governance
    )
    client = ConfigCatClient.get(sdk_key, options)
    client.log.warn('create_client_with_manual_poll is deprecated. Create the ConfigCat Client as a Singleton object with `configcatclient.get()` instead')
    return client
  end

end