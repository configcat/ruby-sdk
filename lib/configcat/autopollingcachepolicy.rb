require 'configcat/interfaces'
require 'concurrent'

module ConfigCat
  class AutoPollingCachePolicy < CachePolicy
    def initialize(config_fetcher, config_cache, poll_interval_seconds=60, max_init_wait_time_seconds=5, on_configuration_changed_callback=nil)
      if poll_interval_seconds < 1
        poll_interval_seconds = 1
      end
      if max_init_wait_time_seconds < 0
        max_init_wait_time_seconds = 0
      end
      @_config_fetcher = config_fetcher
      @_config_cache = config_cache
      @_poll_interval_seconds = poll_interval_seconds
      @_max_init_wait_time_seconds = max_init_wait_time_seconds
      @_on_configuration_changed_callback = on_configuration_changed_callback
      @_initialized = false
      @_is_running = false
      @_start_time = Time.now.utc
      @_lock = Concurrent::ReadWriteLock.new()
      @thread = Thread.new{_run()}
    end

    def _run()
      if @_is_running
        return
      end
      @_is_running = true
      while @_is_running
        force_refresh()
        sleep(@_poll_interval_seconds)
      end
    end

    def get()
      while !@_initialized && (Time.now.utc < @_start_time + @_max_init_wait_time_seconds)
        sleep(0.5)
      end
      begin
        @_lock.acquire_read_lock()
        return @_config_cache.get()
      ensure
        @_lock.release_read_lock()
      end
    end

    def force_refresh()
      begin
        @_lock.acquire_read_lock()
        old_configuration = @_config_cache.get()
      ensure
        @_lock.release_read_lock()
      end
      begin
        configuration = @_config_fetcher.get_configuration_json()
        begin
          @_lock.acquire_write_lock()
          @_config_cache.set(configuration)
          @_initialized = true
        ensure
          @_lock.release_write_lock()
        end
        begin
          if !@_on_configuration_changed_callback.equal?(nil) && configuration != old_configuration
            @_on_configuration_changed_callback.()
          end
        rescue
          # TODO: Logger is needed
          # log.exception(sys.exc_info()[0])
        end
      rescue StandardError => e
        # log.error("Received unexpected response from ConfigFetcher " + e.response.to_s)
        # log.exception(sys.exc_info()[0])
      end
    end

    def stop()
      @_is_running = false
    end
  end
end