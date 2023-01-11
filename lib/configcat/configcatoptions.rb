require 'configcat/datagovernance'
require 'configcat/pollingmode'

module ConfigCat

  class Hooks
    #
    #    Events fired by [ConfigCatClient].
    #

    def initialize(on_client_ready: nil, on_config_changed: nil, on_flag_evaluated: nil, on_error: nil)
      @_on_client_ready_callbacks = on_client_ready ? [on_client_ready] : []
      @_on_config_changed_callbacks = on_config_changed ? [on_config_changed] : []
      @_on_flag_evaluated_callbacks = on_flag_evaluated ? [on_flag_evaluated] : []
      @_on_error_callbacks = on_error ? [on_error] : []
    end

    def add_on_client_ready(callback)
      @_on_client_ready_callbacks.push(callback)
    end

    def add_on_config_changed(callback)
      @_on_config_changed_callbacks.push(callback)
    end

    def add_on_flag_evaluated(callback)
      @_on_flag_evaluated_callbacks.push(callback)
    end

    def add_on_error(callback)
      @_on_error_callbacks.push(callback)
    end

    def invoke_on_client_ready
      @_on_client_ready_callbacks.each { |callback|
        begin
          callback()
        rescue Exception => e
          error = "Exception occurred during invoke_on_client_ready callback: #{e}"
          invoke_on_error(error)
          ConfigCat.logger.error(error)
        end
      }
    end

    def invoke_on_config_changed(config)
      @_on_config_changed_callbacks.each { |callback|
        begin
          callback(config)
        rescue Exception => e
          error = "Exception occurred during invoke_on_config_changed callback: #{e}"
          invoke_on_error(error)
          ConfigCat.logger.error(error)
        end
      }
    end

    def invoke_on_flag_evaluated(evaluation_details)
      @_on_flag_evaluated_callbacks.each { |callback|
        begin
          callback(evaluation_details)
        rescue Exception => e
          error = "Exception occurred during invoke_on_flag_evaluated callback: #{e}"
          invoke_on_error(error)
          ConfigCat.logger.error(error)
        end
      }
    end

    def invoke_on_error(error)
      @_on_error_callbacks.each { |callback|
        begin
          callback(error)
        rescue Exception => e
          ConfigCat.logger.error("Exception occurred during invoke_on_error callback: #{e}")
        end
      }
    end

    def clear
      @_on_client_ready_callbacks.clear
      @_on_config_changed_callbacks.clear
      @_on_flag_evaluated_callbacks.clear
      @_on_error_callbacks.clear
    end
  end

  class ConfigCatOptions
    # Configuration options for ConfigCatClient.
    attr_reader :base_url, :polling_mode, :config_cache, :proxy_address, :proxy_port, :proxy_user, :proxy_pass,
                :open_timeout_seconds, :read_timeout_seconds, :flag_overrides, :data_governance, :default_user,
                :hooks, :offline

    def initialize(base_url: nil,
                   polling_mode: PollingMode.auto_poll(),
                   config_cache: nil,
                   proxy_address: nil,
                   proxy_port: nil,
                   proxy_user: nil,
                   proxy_pass: nil,
                   open_timeout_seconds: 10,
                   read_timeout_seconds: 30,
                   flag_overrides: nil,
                   data_governance: DataGovernance::GLOBAL,
                   default_user: nil,
                   hooks: nil,
                   offline: false)
      # The base ConfigCat CDN url.
      @base_url = base_url

      # The polling mode.
      @polling_mode = polling_mode

      # The cache implementation used to cache the downloaded config files.
      @config_cache = config_cache

      # Proxy address
      @proxy_address = proxy_address

      # Proxy port
      @proxy_port = proxy_port

      # username for proxy authentication
      @proxy_user = proxy_user

      # password for proxy authentication
      @proxy_pass = proxy_pass

      # The number of seconds to wait for the server to make the initial connection
      # (i.e. completing the TCP connection handshake).
      @open_timeout_seconds = open_timeout_seconds

      # The number of seconds to wait for the server to respond before giving up.
      @read_timeout_seconds = read_timeout_seconds

      # Feature flag and setting overrides.
      @flag_overrides = flag_overrides

      # Default: `DataGovernance.Global`. Set this parameter to be in sync with the
      # Data Governance preference on the [Dashboard](https://app.configcat.com/organization/data-governance).
      # (Only Organization Admins have access)
      @data_governance = data_governance

      # The default user to be used for evaluating feature flags and getting settings.
      @default_user = default_user

      # The Hooks instance to subscribe to events.
      @hooks = hooks

      # Indicates whether the client should work in offline mode.
      @offline = offline
    end
  end

end
