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
            client.log.warn(3000, "There is an existing client instance for the specified SDK Key. " \
                                  "No new client instance will be created and the specified options are ignored. " \
                                  "Returning the existing client instance. SDK Key: '#{sdk_key}'.")
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

      if options.flag_overrides
        @_override_data_source = options.flag_overrides.create_data_source(@log)
      else
        @_override_data_source = nil
      end

      # In case of local only flag overrides mode, we accept any SDK Key format.
      if @_override_data_source.nil? || @_override_data_source.get_behaviour() != OverrideBehaviour::LOCAL_ONLY
        is_valid_sdk_key = /^.{22}\/.{22}$/.match?(sdk_key) ||
          /^configcat-sdk-1\/.{22}\/.{22}$/.match?(sdk_key) ||
          (options.base_url && /^configcat-proxy\/.+$/.match?(sdk_key))
        unless is_valid_sdk_key
          raise ConfigCatClientException, "SDK Key `#{sdk_key}` is invalid."
        end
      end

      @_sdk_key = sdk_key
      @_default_user = options.default_user
      @_rollout_evaluator = RolloutEvaluator.new(@log)

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
      config, fetch_time = _get_config()
      if config.nil? || config[FEATURE_FLAGS].nil?
        message = "Config JSON is not present when evaluating setting '#{key}'. Returning the `default_value` parameter that you specified in your application: '#{default_value}'."
        @log.error(1000, message)
        @hooks.invoke_on_flag_evaluated(EvaluationDetails.from_error(key, default_value, error: message))
        return default_value
      end
      details = _evaluate(key, user, default_value, nil, config, fetch_time)
      return details.value
    end

    # Gets the value and evaluation details of a feature flag or setting identified by the given `key`.
    #
    # :param key [String] the identifier of the feature flag or setting.
    # :param default_value in case of any failure, this value will be returned.
    # :param user [User] the user object to identify the caller.
    # :return [EvaluationDetails] the evaluation details.
    def get_value_details(key, default_value, user = nil)
      config, fetch_time = _get_config()
      if config.nil? || config[FEATURE_FLAGS].nil?
        message = "Config JSON is not present when evaluating setting '#{key}'. Returning the `default_value` parameter that you specified in your application: '#{default_value}'."
        @log.error(1000, message)
        details = EvaluationDetails.from_error(key, default_value, error: message)
        @hooks.invoke_on_flag_evaluated(details)
        return details
      end
      details = _evaluate(key, user, default_value, nil, config, fetch_time)
      return details
    end

    # Gets all setting keys.
    #
    # :return list of keys.
    def get_all_keys
      config, _ = _get_config()
      if config.nil?
        @log.error(1000, "Config JSON is not present. Returning empty list.")
        return []
      end
      settings = config.fetch(FEATURE_FLAGS, {})
      return settings.keys
    end

    # Gets the key of a setting, and it's value identified by the given Variation ID (analytics)
    #
    # :param variation_id [String] variation ID
    # :return key and value
    def get_key_and_value(variation_id)
      config, _ = _get_config()
      if config.nil?
        @log.error(1000, "Config JSON is not present. Returning nil.")
        return nil
      end

      settings = config.fetch(FEATURE_FLAGS, {})
      begin
        settings.each do |key, value|
          setting_type = value.fetch(SETTING_TYPE, nil)
          if variation_id == value.fetch(VARIATION_ID, nil)
            return KeyValue.new(key, Config.get_value(value, setting_type))
          end

          targeting_rules = value.fetch(TARGETING_RULES, [])
          targeting_rules.each do |targeting_rule|
            served_value = targeting_rule.fetch(SERVED_VALUE, nil)
            if !served_value.nil? && variation_id == served_value.fetch(VARIATION_ID, nil)
              return KeyValue.new(key, Config.get_value(served_value, setting_type))
            end

            percentage_options = targeting_rule.fetch(PERCENTAGE_OPTIONS, [])
            percentage_options.each do |percentage_option|
              if variation_id == percentage_option.fetch(VARIATION_ID, nil)
                return KeyValue.new(key, Config.get_value(percentage_option, setting_type))
              end
            end
          end

          percentage_options = value.fetch(PERCENTAGE_OPTIONS, [])
          percentage_options.each do |percentage_option|
            if variation_id == percentage_option.fetch(VARIATION_ID, nil)
              return KeyValue.new(key, Config.get_value(percentage_option, setting_type))
            end
          end
        end
      rescue => e
        @log.error("Error occurred in the `#{self.class.name}` method. Returning nil.", event_id: 1002)
        return nil
      end

      @log.error(2011, "Could not find the setting for the specified variation ID: '#{variation_id}'.")
    end

    # Evaluates and returns the values of all feature flags and settings.
    #
    # :param user [User] the user object to identify the caller.
    # :return dictionary of values
    def get_all_values(user = nil)
      config, _ = _get_config()
      if config.nil?
        @log.error(1000, "Config JSON is not present. Returning empty dictionary.")
        return {}
      end

      settings = config.fetch(FEATURE_FLAGS, {})
      all_values = {}
      for key in settings.keys
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
      config, fetch_time = _get_config()
      if config.nil?
        @log.error(1000, "Config JSON is not present. Returning empty list.")
        return []
      end

      details_result = []
      settings = config.fetch(FEATURE_FLAGS, {})
      for key in settings.keys
        details = _evaluate(key, user, nil, nil, config, fetch_time)
        details_result.push(details)
      end

      return details_result
    end

    # Initiates a force refresh on the cached configuration.
    #
    # :return [RefreshResult]
    def force_refresh
      return @_config_service.refresh if @_config_service

      return RefreshResult.new(false,
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
      if @_config_service
        @_config_service.set_online
      else
        @log.warn(3202, "Client is configured to use the `LOCAL_ONLY` override behavior, thus `set_online()` has no effect.")
      end
    end

    # Configures the SDK to not initiate HTTP requests and work only from its cache.
    def set_offline
      @_config_service.set_offline if @_config_service
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

    def _get_config
      if !@_override_data_source.nil?
        behaviour = @_override_data_source.get_behaviour()
        if behaviour == OverrideBehaviour::LOCAL_ONLY
          return @_override_data_source.get_overrides(), Utils::DISTANT_PAST
        elsif behaviour == OverrideBehaviour::REMOTE_OVER_LOCAL
          remote_config, fetch_time = @_config_service.get_config()
          local_config = @_override_data_source.get_overrides()
          remote_config ||= { FEATURE_FLAGS => {} }
          local_config ||= { FEATURE_FLAGS => {} }
          result = local_config.clone()
          result[FEATURE_FLAGS].update(remote_config[FEATURE_FLAGS])
          return result, fetch_time
        elsif behaviour == OverrideBehaviour::LOCAL_OVER_REMOTE
          remote_config, fetch_time = @_config_service.get_config()
          local_config = @_override_data_source.get_overrides()
          remote_config ||= { FEATURE_FLAGS => {} }
          local_config ||= { FEATURE_FLAGS => {} }
          result = remote_config.clone()
          result[FEATURE_FLAGS].update(local_config[FEATURE_FLAGS])
          return result, fetch_time
        end
      end
      return @_config_service.get_config()
    end

    def _check_type_mismatch(value, default_value)
      if !default_value.nil? && Config.is_type_mismatch(value, default_value.class)
        @log.warn(4002, "The type of a setting does not match the type of the specified default value (#{default_value}). " \
                  "Setting's type was #{value.class} but the default value's type was #{default_value.class}. " \
                  "Please make sure that using a default value not matching the setting's type was intended.")
      end
    end

    def _evaluate(key, user, default_value, default_variation_id, config, fetch_time)
      user ||= @_default_user

      # Skip building the evaluation log if it won't be logged.
      log_builder = EvaluationLogBuilder.new if @log.enabled_for?(Logger::INFO)

      value, variation_id, rule, percentage_rule, error = @_rollout_evaluator.evaluate(
        key: key,
        user: user,
        default_value: default_value,
        default_variation_id: default_variation_id,
        config: config,
        log_builder: log_builder)

      _check_type_mismatch(value, default_value)

      @log.info(5000, log_builder.to_s) if log_builder

      details = EvaluationDetails.new(key: key,
                                      value: value,
                                      variation_id: variation_id,
                                      fetch_time: !fetch_time.nil? ? Time.at(fetch_time).utc : nil,
                                      user: user,
                                      is_default_value: error.nil? || error.empty? ? false : true,
                                      error: error,
                                      matched_targeting_rule: rule,
                                      matched_percentage_option: percentage_rule)
      @hooks.invoke_on_flag_evaluated(details)
      return details
    end
  end
end
