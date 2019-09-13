require 'configcat/interfaces'
require 'configcat/configcache'

module ConfigCat
  class ConfigCatClient
    def initialize(api_key,
                   poll_interval_seconds=60,
                   max_init_wait_time_seconds=5,
                   on_configuration_changed_callback=nil,
                   cache_time_to_live_seconds=60,
                   config_cache_class=nil,
                   base_url=nil)
      if api_key === nil
        raise ConfigCatClientException, "API Key is required."
      end
      @_api_key = api_key

      if config_cache_class
        @_config_cache = config_cache_class.()
      else
        @_config_cache = InMemoryConfigCache.new()
      end

      # if poll_interval_seconds > 0
      #   @_config_fetcher = CacheControlConfigFetcher.new(api_key, "p", base_url)
      #   @_cache_policy = AutoPollingCachePolicy.new(@_config_fetcher, @_config_cache, poll_interval_seconds, max_init_wait_time_seconds, on_configuration_changed_callback)
      # else
      #   if cache_time_to_live_seconds > 0
      #     @_config_fetcher = CacheControlConfigFetcher.new(api_key, "l", base_url)
      #     @_cache_policy = LazyLoadingCachePolicy.new(@_config_fetcher, @_config_cache, cache_time_to_live_seconds)
      #   else
      #     @_config_fetcher = CacheControlConfigFetcher.new(api_key, "m", base_url)
      #     @_cache_policy = ManualPollingCachePolicy.new(@_config_fetcher, @_config_cache)
      #   end
      # end
    end

    def get_value(key, default_value, user=nil)
      # config = @_cache_policy.get()
      if config === nil
        return default_value
      end
      # return RolloutEvaluator.evaluate(key, user, default_value, config)
    end

    def get_all_keys()
      config = @_cache_policy.get()
      if config === nil
        return []
      end
      return config.to_a
    end

    def force_refresh()
      @_cache_policy.force_refresh()
    end

    def stop()
      @_cache_policy.stop()
      @_config_fetcher.close()
    end

  end
end
