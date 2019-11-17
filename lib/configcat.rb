require 'configcat/interfaces'
require 'configcat/configcatclient'
require 'configcat/user'
require 'logger'

module ConfigCat

  @logger = Logger.new(STDOUT, level: Logger::WARN)
  class << self
    attr_accessor :logger
  end

  def ConfigCat.create_client(api_key)
    #
    #   Create an instance of ConfigCatClient and setup Auto Poll mode with default options
    #
    #   :param api_key: ConfigCat ApiKey to access your configuration.
    #
    return create_client_with_auto_poll(api_key)
  end

  def ConfigCat.create_client_with_auto_poll(api_key,
                                             poll_interval_seconds: 60,
                                             max_init_wait_time_seconds: 5,
                                             on_configuration_changed_callback: nil,
                                             config_cache_class: nil,
                                             base_url: nil,
                                             proxy_address:nil,
                                             proxy_port:nil,
                                             proxy_user:nil,
                                             proxy_pass:nil)
    #
    #   Create an instance of ConfigCatClient and setup Auto Poll mode with custom options
    #
    #   :param api_key: ConfigCat ApiKey to access your configuration.
    #   :param poll_interval_seconds: The client's poll interval in seconds. Default: 60 seconds.
    #   :param on_configuration_changed_callback: You can subscribe to configuration changes with this callback
    #   :param max_init_wait_time_seconds: maximum waiting time for first configuration fetch in polling mode.
    #   :param config_cache_class: If you want to use custom caching instead of the client's default InMemoryConfigCache,
    #   You can provide an implementation of ConfigCache.
    #   :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
    #   :param proxy_address: Proxy address
    #   :param proxy_port: Proxy port
    #   :param proxy_user: username for proxy authentication
    #   :param proxy_pass: password for proxy authentication
    #
    if api_key === nil
      raise ConfigCatClientException, "API Key is required."
    end
    if poll_interval_seconds < 1
      poll_interval_seconds = 1
    end
    if max_init_wait_time_seconds < 0
      max_init_wait_time_seconds = 0
    end
    return ConfigCatClient.new(api_key,
                               poll_interval_seconds: poll_interval_seconds,
                               max_init_wait_time_seconds: max_init_wait_time_seconds,
                               on_configuration_changed_callback: on_configuration_changed_callback,
                               cache_time_to_live_seconds: 0,
                               config_cache_class: config_cache_class,
                               base_url: base_url,
                               proxy_address: proxy_address,
                               proxy_port: proxy_port,
                               proxy_user: proxy_user,
                               proxy_pass: proxy_pass)
  end

  def ConfigCat.create_client_with_lazy_load(api_key,
                                             cache_time_to_live_seconds: 60,
                                             config_cache_class: nil,
                                             base_url: nil,
                                             proxy_address:nil,
                                             proxy_port:nil,
                                             proxy_user:nil,
                                             proxy_pass:nil)
    #
    #   Create an instance of ConfigCatClient and setup Lazy Load mode with custom options
    #
    #   :param api_key: ConfigCat ApiKey to access your configuration.
    #   :param cache_time_to_live_seconds: The cache TTL.
    #   :param config_cache_class: If you want to use custom caching instead of the client's default InMemoryConfigCache,
    #   You can provide an implementation of ConfigCache.
    #   :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
    #   :param proxy_address: Proxy address
    #   :param proxy_port: Proxy port
    #   :param proxy_user: username for proxy authentication
    #   :param proxy_pass: password for proxy authentication
    #
    if api_key === nil
      raise ConfigCatClientException, "API Key is required."
    end
    if cache_time_to_live_seconds < 1
      cache_time_to_live_seconds = 1
    end
    return ConfigCatClient.new(api_key,
                               poll_interval_seconds: 0,
                               max_init_wait_time_seconds: 0,
                               on_configuration_changed_callback: nil,
                               cache_time_to_live_seconds: cache_time_to_live_seconds,
                               config_cache_class: config_cache_class,
                               base_url: base_url,
                               proxy_address: proxy_address,
                               proxy_port: proxy_port,
                               proxy_user: proxy_user,
                               proxy_pass: proxy_pass)
  end

  def ConfigCat.create_client_with_manual_poll(api_key,
                                               config_cache_class: nil,
                                               base_url: nil,
                                               proxy_address:nil,
                                               proxy_port:nil,
                                               proxy_user:nil,
                                               proxy_pass:nil)
    #
    #   Create an instance of ConfigCatClient and setup Manual Poll mode with custom options
    #
    #   :param api_key: ConfigCat ApiKey to access your configuration.
    #   :param config_cache_class: If you want to use custom caching instead of the client's default InMemoryConfigCache,
    #   You can provide an implementation of ConfigCache.
    #   :param base_url: You can set a base_url if you want to use a proxy server between your application and ConfigCat
    #   :param proxy_address: Proxy address
    #   :param proxy_port: Proxy port
    #   :param proxy_user: username for proxy authentication
    #   :param proxy_pass: password for proxy authentication
    #
    if api_key === nil
      raise ConfigCatClientException, "API Key is required."
    end
    return ConfigCatClient.new(api_key,
                               poll_interval_seconds: 0,
                               max_init_wait_time_seconds: 0,
                               on_configuration_changed_callback: nil,
                               cache_time_to_live_seconds: 0,
                               config_cache_class: config_cache_class,
                               base_url: base_url,
                               proxy_address: proxy_address,
                               proxy_port: proxy_port,
                               proxy_user: proxy_user,
                               proxy_pass: proxy_pass)
  end

end