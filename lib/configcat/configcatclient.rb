require 'configcat/interfaces'
require 'configcat/configcache'
require 'configcat/configcatoptions'
require 'configcat/configfetcher'
require 'configcat/autopollingcachepolicy'
require 'configcat/manualpollingcachepolicy'
require 'configcat/lazyloadingcachepolicy'
require 'configcat/rolloutevaluator'
require 'configcat/utils'
require 'configcat/configcatlogger'
require 'configcat/overridedatasource'
require 'configcat/configservice'
require 'configcat/evaluationdetails'


module ConfigCat
  KeyValue = Struct.new(:key, :value)
  class ConfigCatClient
    attr_reader :log

    @@lock = Mutex.new
    @@instances = {}

    def self.get(sdk_key, options: nil)
      @@lock.synchronize do
        client = @@instances[sdk_key]
        if client
          if options
            client.log.warn("Client for sdk_key `#{sdk_key}` is already created and will be reused; " +
                                  "options passed are being ignored.")
          end
          return client
        end

        options ||= ConfigCatOptions.new
        client = ConfigCatClient.new(sdk_key, options: options)
        @@instances[sdk_key] = client
        return client
      end
    end

    def self.close_all
      @@lock.synchronize do
        @@instances.each do |key, value|
          value.send(:_close_resources)
        end
        @@instances.clear
      end
    end

    private def initialize(sdk_key, options: ConfigCatOptions.new)
      @_hooks = options.hooks || Hooks.new
      @log = ConfigCatLogger.new(@_hooks)

      if sdk_key === nil
        raise ConfigCatClientException, "SDK Key is required."
      end

      @_sdk_key = sdk_key
      @_default_user = options.default_user
      @_rollout_evaluator = RolloutEvaluator.new(@log)
      if options.flag_overrides
        @_override_data_source = options.flag_overrides.create_data_source(@log)
      else
        @_override_data_source = nil
      end

      @config_cache = options.config_cache.nil? ? NullConfigCache.new : options.config_cache

      if @_override_data_source && @_override_data_source.get_behaviour() == OverrideBehaviour::LOCAL_ONLY
        @_config_fetcher = nil
        @_config_service = nil
      else
        @_config_fetcher = ConfigFetcher.new(@_sdk_key,
                                            @log,
                                            options.polling_mode.identifier,
                                            base_url: options.base_url,
                                            proxy_address: options.proxy_address,
                                            proxy_port: options.proxy_port,
                                            proxy_user: options.proxy_user,
                                            proxy_pass: options.proxy_pass,
                                            open_timeout: options.open_timeout_seconds,
                                            read_timeout: options.read_timeout_seconds,
                                            data_governance: options.data_governance)

        @_config_service = ConfigService.new(@sdk_key,
                                            options.polling_mode,
                                            @_hooks,
                                            @_config_fetcher,
                                            @log,
                                            @config_cache,
                                            options.offline)
      end
    end

    # Gets the value of a feature flag or setting identified by the given `key`.
    def get_value(key, default_value, user=nil)
      settings, fetch_time = _get_settings()
      if settings.nil?
        message = "Evaluating get_value('%s') failed. Cache is empty. " \
                  "Returning default_value in your get_value call: [%s]." % [key, default_value.to_s]
        @log.error(message)
        @_hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, default_value, error: message))
        return default_value
      end
      details = _evaluate(key, user, default_value, nil, settings, fetch_time)
      return details.value
    end

    # Gets all setting keys.
    def get_all_keys()
      settings, _ = _get_settings()
      if settings === nil
        return []
      end
      return settings.keys
    end

    # Gets the Variation ID (analytics) of a feature flag or setting based on it's key.
    def get_variation_id(key, default_variation_id, user=nil)
      @log.warn("get_variation_id is deprecated and will be removed in a future major version. "\
                "Please use [get_value_details] instead.")

      settings, fetch_time = _get_settings()
      if settings === nil
        message = "Evaluating get_variation_id('%s') failed. Cache is empty. "\
                  "Returning default_variation_id in your get_variation_id call: [%s]." %
                  [key, default_variation_id.to_s]
        @log.error(message)
        @_hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, nil, error: message,
                                                                      variation_id: default_variation_id))
        return default_variation_id
      end
      details = _evaluate(key, user, nil, default_variation_id, settings, fetch_time)
      return details.variation_id
    end

    # Gets the Variation IDs (analytics) of all feature flags or settings.
    def get_all_variation_ids(user: nil)
      @log.warn("get_all_variation_ids is deprecated and will be removed in a future major version. "\
                "Please use [get_value_details] instead.")

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

    # Gets the key of a setting, and it's value identified by the given Variation ID (analytics)
    def get_key_and_value(variation_id)
      settings, _ = _get_settings()
      if settings === nil
        @log.warn("Evaluating get_key_and_value('%s') failed. Cache is empty. Returning nil." % variation_id)
        return nil
      end

      for key, value in settings
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

    def force_refresh
      @_config_service.force_refresh()
    end

    def close
      # Closes the underlying resources.
      @@lock.synchronize do
        _close_resources
        @@instances.delete(@sdk_key)
      end
    end

    private

    def _close_resources
      @_config_service.close() if @_config_service
      @_config_fetcher.close() if @_config_fetcher
      @_hooks.clear
    end

    def _get_settings
      if !@_override_data_source.nil?
        behaviour = @_override_data_source.get_behaviour()
        if behaviour == OverrideBehaviour::LOCAL_ONLY
          return @_override_data_source.get_overrides(), Utils::DISTANT_PAST
        elsif behaviour == OverrideBehaviour::REMOTE_OVER_LOCAL
          remote_settings, fetch_time = @_config_service.get_settings()
          local_settings = @_override_data_source.get_overrides()
          result = local_settings.clone()
          if remote_settings.key?(FEATURE_FLAGS) && local_settings.key?(FEATURE_FLAGS)
            result[FEATURE_FLAGS] = result[FEATURE_FLAGS].merge(remote_settings[FEATURE_FLAGS])
          end
          return result, fetch_time
        elsif behaviour == OverrideBehaviour::LOCAL_OVER_REMOTE
          remote_settings, fetch_time = @_config_service.get_settings()
          local_settings = @_override_data_source.get_overrides()
          result = remote_settings.clone()
          if remote_settings.key?(FEATURE_FLAGS) && local_settings.key?(FEATURE_FLAGS)
            result[FEATURE_FLAGS] = result[FEATURE_FLAGS].merge(local_settings[FEATURE_FLAGS])
          end
          return result, fetch_time
        end
      end
      return @_config_service.get_settings()
    end

    def _get_cache_key
      return Digest::SHA1.hexdigest("ruby_" + CONFIG_FILE_NAME + "_" + @_sdk_key)
    end

    def _evaluate(key, user, default_value, default_variation_id, settings, fetch_time)
      user = user || @_default_user
      value, variation_id, rule, percentage_rule, error = @_rollout_evaluator.evaluate(
          key: key,
          user: user,
          default_value: default_value,
          default_variation_id: default_variation_id,
          settings: settings)

      details = EvaluationDetails.new(key: key,
                                      value: value,
                                      variation_id: variation_id,
                                      fetch_time: fetch_time,
                                      user: user,
                                      is_default_value: true || false,
                                      error: error,
                                      matched_evaluation_rule: rule,
                                      matched_evaluation_percentage_rule: percentage_rule)
      @_hooks.invoke_on_flag_evaluated(details)
      return details
    end

  end
end
