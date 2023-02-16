require 'configcat/interfaces'
require 'configcat/configcache'
require 'configcat/configcatoptions'
require 'configcat/configfetcher'
require 'configcat/rolloutevaluator'
require 'configcat/utils'
require 'configcat/configcatlogger'
require 'configcat/overridedatasource'
require 'configcat/configservice'
require 'configcat/evaluationdetails'


module ConfigCat
  KeyValue = Struct.new(:key, :value)
  class ConfigCatClient
    attr_reader :log, :hooks

    @@lock = Mutex.new
    @@instances = {}

    # Creates a new or gets an already existing `ConfigCatClient` for the given `sdk_key`.
    #
    # :param sdk_key [String] ConfigCat SDK Key to access your configuration.
    # :param options [ConfigCatOptions] Configuration for `ConfigCatClient`.
    # :return [ConfigCatClient] the `ConfigCatClient` instance.
    def self.get(sdk_key, options = nil)
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
        client = ConfigCatClient.new(sdk_key, options)
        @@instances[sdk_key] = client
        return client
      end
    end

    # Closes all ConfigCatClient instances.
    def self.close_all
      @@lock.synchronize do
        @@instances.each do |key, value|
          value.send(:_close_resources)
        end
        @@instances.clear
      end
    end

    private def initialize(sdk_key, options = ConfigCatOptions.new)
      @hooks = options.hooks || Hooks.new
      @log = ConfigCatLogger.new(@hooks)

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

      config_cache = options.config_cache.nil? ? NullConfigCache.new : options.config_cache

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
                                             @hooks,
                                             @_config_fetcher,
                                             @log,
                                             config_cache,
                                             options.offline)
      end
    end

    # Gets the value of a feature flag or setting identified by the given `key`.
    #
    # :param key [String] the identifier of the feature flag or setting.
    # :param default_value in case of any failure, this value will be returned.
    # :param user [User] the user object to identify the caller.
    # :return the value.
    def get_value(key, default_value, user = nil)
      settings, fetch_time = _get_settings()
      if settings.nil?
        message = "Evaluating get_value('%s') failed. Cache is empty. " \
                  "Returning default_value in your get_value call: [%s]." % [key, default_value.to_s]
        @log.error(message)
        @hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, default_value, error: message))
        return default_value
      end
      details = _evaluate(key, user, default_value, nil, settings, fetch_time)
      return details.value
    end

    # Gets the value and evaluation details of a feature flag or setting identified by the given `key`.
    #
    # :param key [String] the identifier of the feature flag or setting.
    # :param default_value in case of any failure, this value will be returned.
    # :param user [User] the user object to identify the caller.
    # :return [EvaluationDetails] the evaluation details.
    def get_value_details(key, default_value, user = nil)
      settings, fetch_time = _get_settings()
      if settings.nil?
        message = "Evaluating get_value_details('%s') failed. Cache is empty. " \
                  "Returning default_value in your get_value_details call: [%s]." % [key, default_value.to_s]
        @log.error(message)
        @hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, default_value, error: message))
        return default_value
      end
      details = _evaluate(key, user, default_value, nil, settings, fetch_time)
      return details
    end

    # Gets all setting keys.
    #
    # :return list of keys.
    def get_all_keys
      settings, _ = _get_settings()
      if settings === nil
        return []
      end
      return settings.keys
    end

    # Gets the Variation ID (analytics) of a feature flag or setting based on it's key.
    #
    # :param key [String] the identifier of the feature flag or setting.
    # :param default_variation_id in case of any failure, this value will be returned.
    # :param user [User] the user object to identify the caller.
    # :return the variation ID.
    def get_variation_id(key, default_variation_id, user = nil)
      @log.warn("get_variation_id is deprecated and will be removed in a future major version. "\
                "Please use [get_value_details] instead.")

      settings, fetch_time = _get_settings()
      if settings === nil
        message = "Evaluating get_variation_id('%s') failed. Cache is empty. "\
                  "Returning default_variation_id in your get_variation_id call: [%s]." %
                  [key, default_variation_id.to_s]
        @log.error(message)
        @hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, nil, error: message,
                                                                     variation_id: default_variation_id))
        return default_variation_id
      end
      details = _evaluate(key, user, nil, default_variation_id, settings, fetch_time)
      return details.variation_id
    end

    # Gets the Variation IDs (analytics) of all feature flags or settings.
    #
    # :param user [User] the user object to identify the caller.
    # :return list of variation IDs
    def get_all_variation_ids(user = nil)
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
    #
    # :param variation_id [String] variation ID
    # :return key and value
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

      @log.error("Could not find the setting for the given variation_id: " + variation_id)
    end

    # Evaluates and returns the values of all feature flags and settings.
    #
    # :param user [User] the user object to identify the caller.
    # :return dictionary of values
    def get_all_values(user = nil)
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

    # Gets the values along with evaluation details of all feature flags and settings.
    #
    # :param user [User] the user object to identify the caller.
    # :return list of all evaluation details
    def get_all_value_details(user = nil)
      settings, fetch_time = _get_settings()
      if settings.nil?
        @log.error("Evaluating get_all_value_details() failed. Cache is empty. Returning empty list.")
        return []
      end

      details_result = []
      for key in settings.keys
        details = _evaluate(key, user, nil, nil, settings, fetch_time)
        details_result.push(details)
      end

      return details_result
    end

    # Initiates a force refresh on the cached configuration.
    #
    # :return [RefreshResult]
    def force_refresh
      return @_config_service.refresh if @_config_service

      return RefreshResult(false,
                           "The SDK uses the LocalOnly flag override behavior which prevents making HTTP requests.")
    end

    # Sets the default user.
    #
    # :param user [User] the user object to identify the caller.
    def set_default_user(user)
      @_default_user = user
    end

    # Sets the default user to nil.
    def clear_default_user
      @_default_user = nil
    end

    # Configures the SDK to allow HTTP requests.
    def set_online
      @_config_service.set_online if @_config_service
      @log.debug('Switched to ONLINE mode.')
    end

    # Configures the SDK to not initiate HTTP requests and work only from its cache.
    def set_offline
      @_config_service.set_offline if @_config_service
      @log.debug('Switched to OFFLINE mode.')
    end

    # Returns true when the SDK is configured not to initiate HTTP requests, otherwise false.
    def offline?
      return @_config_service ? @_config_service.offline? : true
    end

    # Closes the underlying resources.
    def close
      @@lock.synchronize do
        _close_resources
        @@instances.delete(@_sdk_key)
      end
    end

    private

    def _close_resources
      @_config_service.close if @_config_service
      @_config_fetcher.close if @_config_fetcher
      @hooks.clear
    end

    def _get_settings
      if !@_override_data_source.nil?
        behaviour = @_override_data_source.get_behaviour()
        if behaviour == OverrideBehaviour::LOCAL_ONLY
          return @_override_data_source.get_overrides(), Utils::DISTANT_PAST
        elsif behaviour == OverrideBehaviour::REMOTE_OVER_LOCAL
          remote_settings, fetch_time = @_config_service.get_settings()
          local_settings = @_override_data_source.get_overrides()
          remote_settings ||= {}
          local_settings ||= {}
          result = local_settings.clone()
          result.update(remote_settings)
          return result, fetch_time
        elsif behaviour == OverrideBehaviour::LOCAL_OVER_REMOTE
          remote_settings, fetch_time = @_config_service.get_settings()
          local_settings = @_override_data_source.get_overrides()
          remote_settings ||= {}
          local_settings ||= {}
          result = remote_settings.clone()
          result.update(local_settings)
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
                                      fetch_time: !fetch_time.nil? ? Time.at(fetch_time).utc : nil,
                                      user: user,
                                      is_default_value: error.nil? || error.empty? ? false : true,
                                      error: error,
                                      matched_evaluation_rule: rule,
                                      matched_evaluation_percentage_rule: percentage_rule)
      @hooks.invoke_on_flag_evaluated(details)
      return details
    end
  end
end
