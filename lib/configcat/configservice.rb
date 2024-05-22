require 'concurrent'
require 'configcat/configentry'
require 'configcat/pollingmode'
require 'configcat/refreshresult'


module ConfigCat
  class ConfigService
    def initialize(sdk_key, polling_mode, hooks, config_fetcher, log, config_cache, is_offline)
      @cached_entry = ConfigEntry::EMPTY
      @cached_entry_string = ''
      @polling_mode = polling_mode
      @log = log
      @config_cache = config_cache
      @hooks = hooks
      @cache_key = ConfigService.get_cache_key(sdk_key)
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

    def get_config
      threshold = Utils::DISTANT_PAST
      prefer_cached = @initialized.set?
      if @polling_mode.is_a?(LazyLoadingMode)
        threshold = Utils.get_utc_now_seconds_since_epoch - @polling_mode.cache_refresh_interval_seconds
        prefer_cached = false
      elsif @polling_mode.is_a?(AutoPollingMode) && !@initialized.set?
        elapsed_time = Utils.get_utc_now_seconds_since_epoch - @start_time # Elapsed time in seconds
        threshold = Utils.get_utc_now_seconds_since_epoch - @polling_mode.poll_interval_seconds
        if elapsed_time < @polling_mode.max_init_wait_time_seconds
          @initialized.wait(@polling_mode.max_init_wait_time_seconds - elapsed_time)

          # Max wait time expired without result, notify subscribers with the cached config.
          if !@initialized.set?
            set_initialized
            return !@cached_entry.empty? ?
              [@cached_entry.config, @cached_entry.fetch_time] :
              [nil, Utils::DISTANT_PAST]
          end
        end
      end

      # If we are initialized, we prefer the cached results
      entry, _ = fetch_if_older(threshold, prefer_cached: prefer_cached)
      return !entry.empty? ?
        [entry.config, entry.fetch_time] :
        [nil, Utils::DISTANT_PAST]
    end

    # :return [RefreshResult]
    def refresh
      if offline?
        offline_warning = "Client is in offline mode, it cannot initiate HTTP calls."
        @log.warn(3200, offline_warning)
        return RefreshResult.new(success = false, error = offline_warning)
      end

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
        @log.info(5200, "Switched to ONLINE mode.")
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

        @log.info(5200, "Switched to OFFLINE mode.")
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

    def self.get_cache_key(sdk_key)
      Digest::SHA1.hexdigest("#{sdk_key}_#{CONFIG_FILE_NAME}.json_#{SERIALIZATION_FORMAT_VERSION}")
    end

    # :return [ConfigEntry, String] Returns the ConfigEntry object and error message in case of any error.
    def fetch_if_older(threshold, prefer_cached: false)
      # Sync up with the cache and use it when it's not expired.
      @lock.synchronize do
        # Sync up with the cache and use it when it's not expired.
        from_cache = read_cache
        if !from_cache.empty? && from_cache.etag != @cached_entry.etag
          @cached_entry = from_cache
          @hooks.invoke_on_config_changed(from_cache.config[FEATURE_FLAGS])
        end

        # Cache isn't expired
        if @cached_entry.fetch_time > threshold
          set_initialized
          return @cached_entry, nil
        end

        # If we are in offline mode or the caller prefers cached values, do not initiate fetch.
        if @is_offline || prefer_cached
          return @cached_entry, nil
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
        return ConfigEntry.create_from_string(json_string)
      rescue Exception => e
        @log.error(2200, "Error occurred while reading the cache. #{e}")
        return ConfigEntry::EMPTY
      end
    end

    def write_cache(config_entry)
      begin
        @config_cache.set(@cache_key, config_entry.serialize)
      rescue Exception => e
        @log.error(2201, "Error occurred while writing the cache. #{e}")
      end
    end
  end
end
