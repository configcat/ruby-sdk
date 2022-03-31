require 'configcat/interfaces'
require 'configcat/configcache'
require 'configcat/configfetcher'
require 'configcat/autopollingcachepolicy'
require 'configcat/manualpollingcachepolicy'
require 'configcat/lazyloadingcachepolicy'
require 'configcat/rolloutevaluator'
require 'configcat/datagovernance'


module ConfigCat
  KeyValue = Struct.new(:key, :value)
  class ConfigCatClient
    @@sdk_keys = []

    def initialize(sdk_key,
                   poll_interval_seconds: 60,
                   max_init_wait_time_seconds: 5,
                   on_configuration_changed_callback: nil,
                   cache_time_to_live_seconds: 60,
                   config_cache_class: nil,
                   base_url: nil,
                   proxy_address: nil,
                   proxy_port: nil,
                   proxy_user: nil,
                   proxy_pass: nil,
                   open_timeout: 10,
                   read_timeout: 30,
                   flag_overrides: nil,
                   data_governance: DataGovernance::GLOBAL)
      if sdk_key === nil
        raise ConfigCatClientException, "SDK Key is required."
      end

      if @@sdk_keys.include?(sdk_key)
        ConfigCat.logger.warn("A ConfigCat Client is already initialized with sdk_key %s. "\
                              "We strongly recommend you to use the ConfigCat Client as "\
                              "a Singleton object in your application." % sdk_key)
      else
        @@sdk_keys.push(sdk_key)
      end

      @_sdk_key = sdk_key
      @_override_data_source = flag_overrides

      if config_cache_class
        @_config_cache = config_cache_class.new()
      else
        @_config_cache = InMemoryConfigCache.new()
      end

      if !@_override_data_source.equal?(nil) && @_override_data_source.get_behaviour() == OverrideBehaviour::LOCAL_ONLY
        @_config_fetcher = nil
        @_cache_policy = nil
      else
        if poll_interval_seconds > 0
          @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "p", base_url: base_url,
                                                           proxy_address: proxy_address, proxy_port: proxy_port, proxy_user: proxy_user, proxy_pass: proxy_pass,
                                                           open_timeout: open_timeout, read_timeout: read_timeout,
                                                           data_governance: data_governance)
          @_cache_policy = AutoPollingCachePolicy.new(@_config_fetcher, @_config_cache, _get_cache_key(), poll_interval_seconds, max_init_wait_time_seconds, on_configuration_changed_callback)
        else
          if cache_time_to_live_seconds > 0
            @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "l", base_url: base_url,
                                                             proxy_address: proxy_address, proxy_port: proxy_port, proxy_user: proxy_user, proxy_pass: proxy_pass,
                                                             open_timeout: open_timeout, read_timeout: read_timeout,
                                                             data_governance: data_governance)
            @_cache_policy = LazyLoadingCachePolicy.new(@_config_fetcher, @_config_cache, _get_cache_key(), cache_time_to_live_seconds)
          else
            @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "m", base_url: base_url,
                                                             proxy_address: proxy_address, proxy_port: proxy_port, proxy_user: proxy_user, proxy_pass: proxy_pass,
                                                             open_timeout: open_timeout, read_timeout: read_timeout,
                                                             data_governance: data_governance)
            @_cache_policy = ManualPollingCachePolicy.new(@_config_fetcher, @_config_cache, _get_cache_key())
          end
        end
      end
    end

    def get_value(key, default_value, user=nil)
      config = _get_settings()
      if config === nil
        ConfigCat.logger.warn("Evaluating get_value('%s') failed. Cache is empty. "\
                              "Returning default_value in your get_value call: [%s]." % [key, default_value.to_s])
        return default_value
      end
      value, variation_id = RolloutEvaluator.evaluate(key, user, default_value, nil, config)
      return value
    end

    def get_all_keys()
      config = _get_settings()
      if config === nil
        return []
      end
      feature_flags = config.fetch(FEATURE_FLAGS, nil)
      if feature_flags === nil
        return []
      end
      return feature_flags.keys
    end

    def get_variation_id(key, default_variation_id, user=nil)
      config = _get_settings()
      if config === nil
        ConfigCat.logger.warn("Evaluating get_variation_id('%s') failed. Cache is empty. "\
                              "Returning default_variation_id in your get_variation_id call: [%s]." %
                              [key, default_variation_id.to_s])
        return default_variation_id
      end
      value, variation_id = RolloutEvaluator.evaluate(key, user, nil, default_variation_id, config)
      return variation_id
    end

    def get_all_variation_ids(user: nil)
      keys = get_all_keys()
      variation_ids = []
      for key in keys
        variation_id = get_variation_id(key, nil, user)
        if !variation_id.equal?(nil)
          variation_ids.push(variation_id)
        end
      end
      return variation_ids
    end

    def get_key_and_value(variation_id)
      config = _get_settings()
      if config === nil
        ConfigCat.logger.warn("Evaluating get_variation_id('%s') failed. Cache is empty. Returning nil." % variation_id)
        return nil
      end

      feature_flags = config.fetch(FEATURE_FLAGS, nil)
      if feature_flags === nil
        ConfigCat.logger.warn("Evaluating get_key_and_value('%s') failed. Cache is empty. Returning None." % variation_id)
        return nil
      end

      for key, value in feature_flags
        if variation_id == value.fetch(VARIATION_ID, nil)
          return KeyValue.new(key, value[VALUE])
        end

        rollout_rules = value.fetch(ROLLOUT_RULES, [])
        for rollout_rule in rollout_rules
          if variation_id == rollout_rule.fetch(VARIATION_ID, nil)
            return KeyValue.new(key, rollout_rule[VALUE])
          end
        end

        rollout_percentage_items = value.fetch(ROLLOUT_PERCENTAGE_ITEMS, [])
        for rollout_percentage_item in rollout_percentage_items
          if variation_id == rollout_percentage_item.fetch(VARIATION_ID, nil)
            return KeyValue.new(key, rollout_percentage_item[VALUE])
          end
        end
      end
    end

    def get_all_values(user: nil)
      keys = get_all_keys()
      all_values = {}
      for key in keys
        value = get_value(key, nil, user)
        if !value.equal?(nil)
          all_values[key] = value
        end
      end
      return all_values
    end

    def force_refresh()
      @_cache_policy.force_refresh()
    end

    def stop()
      @_cache_policy.stop() if @_cache_policy
      @_config_fetcher.close() if @_config_fetcher
      @@sdk_keys.delete(@_sdk_key)
    end

    private

    def _get_settings()
      if !@_override_data_source.nil?
        behaviour = @_override_data_source.get_behaviour()
        if behaviour == OverrideBehaviour::LOCAL_ONLY
          return @_override_data_source.get_overrides()
        else
          if behaviour == OverrideBehaviour::REMOTE_OVER_LOCAL
            remote_settings = @_cache_policy.get()
            local_settings = @_override_data_source.get_overrides()
            result = local_settings.clone()
            if remote_settings.key?(FEATURE_FLAGS) && local_settings.key?(FEATURE_FLAGS)
              result[FEATURE_FLAGS] = result[FEATURE_FLAGS].merge(remote_settings[FEATURE_FLAGS])
            end
            return result
          else
            if behaviour == OverrideBehaviour::LOCAL_OVER_REMOTE
              remote_settings = @_cache_policy.get()
              local_settings = @_override_data_source.get_overrides()
              result = remote_settings.clone()
              if remote_settings.key?(FEATURE_FLAGS) && local_settings.key?(FEATURE_FLAGS)
                result[FEATURE_FLAGS] = result[FEATURE_FLAGS].merge(local_settings[FEATURE_FLAGS])
              end
              return result
            end
          end
        end
      end
      return @_cache_policy.get()
    end

    def _get_cache_key()
      return Digest::SHA1.hexdigest("ruby_" + CONFIG_FILE_NAME + "_" + @_sdk_key)
    end

  end
end
