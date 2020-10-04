require 'configcat/interfaces'
require 'configcat/constants'
require 'concurrent'

module ConfigCat
  class AutoPollingCachePolicy < CachePolicy
    def initialize(config_fetcher, config_cache, cache_key, poll_interval_seconds=60, max_init_wait_time_seconds=5, on_configuration_changed_callback=nil)
      if poll_interval_seconds < 1
        poll_interval_seconds = 1
      end
      if max_init_wait_time_seconds < 0
        max_init_wait_time_seconds = 0
      end
      @_config_fetcher = config_fetcher
      @_config_cache = config_cache
      @_cache_key = cache_key
      @_poll_interval_seconds = poll_interval_seconds
      @_max_init_wait_time_seconds = max_init_wait_time_seconds
      @_on_configuration_changed_callback = on_configuration_changed_callback
      @_initialized = false
      @_is_running = false
      @_start_time = Time.now.utc
      @_lock = Concurrent::ReadWriteLock.new()
      @_is_started = Concurrent::Event.new()
      @thread = Thread.new{_run()}
      @_is_started.wait()
    end

    def _run()
      @_is_running = true
      @_is_started.set()
      loop do
        force_refresh()
        sleep(@_poll_interval_seconds)
        break if !@_is_running
      end
    end

    def get()
      while !@_initialized && (Time.now.utc < @_start_time + @_max_init_wait_time_seconds)
        sleep(0.5)
      end
      begin
        @_lock.acquire_read_lock()
        return @_config_cache.get(@_cache_key)
      ensure
        @_lock.release_read_lock()
      end
    end

    def force_refresh()
      begin
        configuration_response = @_config_fetcher.get_configuration_json()

        begin
          @_lock.acquire_read_lock()
          old_configuration = @_config_cache.get(@_cache_key)
        ensure
          @_lock.release_read_lock()
        end

        if configuration_response.is_fetched()
          configuration = configuration_response.json()
          if configuration != old_configuration
            begin
              @_lock.acquire_write_lock()
              @_config_cache.set(@_cache_key, configuration)
              @_initialized = true
            ensure
              @_lock.release_write_lock()
            end
            begin
              if !@_on_configuration_changed_callback.equal?(nil)
                @_on_configuration_changed_callback.()
              end
            rescue Exception => e
              ConfigCat.logger.error("Exception in on_configuration_changed_callback: #{e.class}:'#{e}'")
            end
          end
        end

        if !@_initialized && !old_configuration.equal?(nil)
          @_initialized = true
        end
      rescue Exception => e
        ConfigCat.logger.error("Double-check your SDK Key at https://app.configcat.com/sdkkey.")
        ConfigCat.logger.error "threw exception #{e.class}:'#{e}'"
        ConfigCat.logger.error "stacktrace: #{e.backtrace}"
      end
    end

    def stop()
      @_is_running = false
    end
  end
end
