require 'concurrent'
require 'configcat/configentry'
require 'configcat/pollingmode'
require 'configcat/refreshresult'


module ConfigCat
  class ConfigService
    def initialize(sdk_key, polling_mode, hooks, config_fetcher, log, config_cache, is_offline)
      @sdk_key = sdk_key
      @cached_entry = ConfigEntry::EMPTY
      @cached_entry_string = ''
      @polling_mode = polling_mode
      @log = log
      @config_cache = config_cache
      @hooks = hooks
      @cache_key = Digest::SHA1.hexdigest("ruby_#{CONFIG_FILE_NAME}_#{@sdk_key}")
      @config_fetcher = config_fetcher
      @is_offline = is_offline
      @response_future = nil
      @initialized = Concurrent::Event.new
      @lock = Mutex.new
      @ongoing_fetch = false
      @fetch_finished = Concurrent::Event.new
      @start_time = Utils.get_utc_now_seconds_since_epoch

      if @polling_mode.is_a?(AutoPollingMode) && !@is_offline
        start_poll
      else
        set_initialized
      end
    end

    def get_settings
      if @polling_mode.is_a?(LazyLoadingMode)
        entry, _ = fetch_if_older(Utils.get_utc_now_seconds_since_epoch - @polling_mode.cache_refresh_interval_seconds)
        return !entry.empty? ?
          [entry.config.fetch(FEATURE_FLAGS, {}), entry.fetch_time] :
          [nil, Utils::DISTANT_PAST]
          
      elsif @polling_mode.is_a?(AutoPollingMode) && !@initialized.set?
        elapsed_time = Utils.get_utc_now_seconds_since_epoch - @start_time # Elapsed time in seconds
        if elapsed_time < @polling_mode.max_init_wait_time_seconds
          @initialized.wait(@polling_mode.max_init_wait_time_seconds - elapsed_time)

          # Max wait time expired without result, notify subscribers with the cached config.
          if !@initialized.set?
            set_initialized
            return !@cached_entry.empty? ?
              [@cached_entry.config.fetch(FEATURE_FLAGS, {}), @cached_entry.fetch_time] :
              [nil, Utils::DISTANT_PAST]
          end
        end
      end

      entry, _ = fetch_if_older(Utils::DISTANT_PAST, prefer_cache: true)
      return !entry.empty? ?
        [entry.config.fetch(FEATURE_FLAGS, {}), entry.fetch_time] :
        [nil, Utils::DISTANT_PAST]
    end

    # :return [RefreshResult]
    def refresh
      _, error = fetch_if_older(Utils::DISTANT_FUTURE)
      return RefreshResult.new(success = error.nil?, error = error)
    end

    def set_online
      @lock.synchronize do
        if !@is_offline
          return
        end

        @is_offline = false
        if @polling_mode.is_a?(AutoPollingMode)
          start_poll
        end
        @log.info(5200, 'Switched to ONLINE mode.')
      end
    end

    def set_offline
      @lock.synchronize do
        if @is_offline
          return
        end

        @is_offline = true
        if @polling_mode.is_a?(AutoPollingMode)
          @stopped.set
          @thread.join
        end

        @log.info(5200, 'Switched to OFFLINE mode.')
      end
    end

    def offline?
      return @is_offline
    end

    def close
      if @polling_mode.is_a?(AutoPollingMode)
        @stopped.set
      end
    end

    private

    # :return [ConfigEntry, String] Returns the ConfigEntry object and error message in case of any error.
    def fetch_if_older(time, prefer_cache: false)
      # Sync up with the cache and use it when it's not expired.
      @lock.synchronize do
        if @cached_entry.empty? || @cached_entry.fetch_time > time
          entry = read_cache
          if !entry.empty? && entry.etag != @cached_entry.etag
            @cached_entry = entry
            @hooks.invoke_on_config_changed(entry.config[FEATURE_FLAGS])
          end

          # Cache isn't expired
          if @cached_entry.fetch_time > time
            set_initialized
            return @cached_entry, nil
          end
        end

        # Use cache anyway (get calls on auto & manual poll must not initiate fetch).
        # The initialized check ensures that we subscribe for the ongoing fetch during the
        # max init wait time window in case of auto poll.
        if prefer_cache && @initialized.set?
          return @cached_entry, nil
        end

        # If we are in offline mode we are not allowed to initiate fetch.
        if @is_offline
          offline_warning = "Client is in offline mode, it cannot initiate HTTP calls."
          @log.warn(3200, offline_warning)
          return @cached_entry, offline_warning
        end
      end

      # No fetch is running, initiate a new one.
      # Ensure only one fetch request is running at a time.
      # If there's an ongoing fetch running, we will wait for the ongoing fetch.
      if @ongoing_fetch
        @fetch_finished.wait
      else
        @ongoing_fetch = true
        @fetch_finished.reset
        response = @config_fetcher.get_configuration(@cached_entry.etag)

        @lock.synchronize do
          if response.is_fetched
            @cached_entry = response.entry
            write_cache(response.entry)
            @hooks.invoke_on_config_changed(response.entry.config[FEATURE_FLAGS])
          elsif (response.is_not_modified || !response.is_transient_error) && !@cached_entry.empty?
            @cached_entry.fetch_time = Utils.get_utc_now_seconds_since_epoch
            write_cache(@cached_entry)
          end

          set_initialized
        end

        @ongoing_fetch = false
        @fetch_finished.set
      end

      return @cached_entry, nil
    end

    def start_poll
      @started = Concurrent::Event.new
      @thread = Thread.new { run() }
      @started.wait()
    end

    def run
      @stopped = Concurrent::Event.new
      @started.set
      loop do
        fetch_if_older(Utils.get_utc_now_seconds_since_epoch - @polling_mode.poll_interval_seconds)
        @stopped.wait(@polling_mode.poll_interval_seconds)
        break if @stopped.set?
      end
    end

    def set_initialized
      if !@initialized.set?
        @initialized.set
        @hooks.invoke_on_client_ready
      end
    end

    def read_cache
      begin
        json_string = @config_cache.get(@cache_key)
        if !json_string || json_string == @cached_entry_string
          return ConfigEntry::EMPTY
        end

        @cached_entry_string = json_string
        return ConfigEntry.create_from_json(JSON.parse(json_string))
      rescue Exception => e
        @log.error(2200, "Error occurred while reading the cache. #{e}")
        return ConfigEntry::EMPTY
      end
    end

    def write_cache(config_entry)
      begin
        @config_cache.set(@cache_key, config_entry.to_json.to_json)
      rescue Exception => e
        @log.error(2201, "Error occurred while writing the cache. #{e}")
      end
    end
  end
end
