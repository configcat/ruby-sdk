require 'configcat/interfaces'
require 'concurrent'

module ConfigCat
  class LazyLoadingCachePolicy < CachePolicy

    def initialize(config_fetcher, config_cache, cache_time_to_live_seconds=60)
      if cache_time_to_live_seconds < 1
        cache_time_to_live_seconds = 1
      end
      @_config_fetcher = config_fetcher
      @_config_cache = config_cache
      @_cache_time_to_live = cache_time_to_live_seconds
      @_lock = Concurrent::ReadWriteLock.new()
      @_last_updated = nil
    end

    def get()
      begin
        @_lock.acquire_read_lock()
        utc_now = Time.now.utc
        if !@_last_updated.equal?(nil) && (@_last_updated + @_cache_time_to_live > utc_now)
          config = @_config_cache.get()
          if !config.equal?(nil)
            return config
          end
        end
      ensure
        @_lock.release_read_lock()
      end
      force_refresh()
      begin
        @_lock.acquire_read_lock()
        config = @_config_cache.get()
        return config
      ensure
        @_lock.release_read_lock()
      end
    end

    def force_refresh()
      begin
        configuration = @_config_fetcher.get_configuration_json()
        begin
          @_lock.acquire_write_lock()
          @_config_cache.set(configuration)
          @_last_updated = Time.now.utc
        ensure
          @_lock.release_write_lock()
        end
      rescue StandardError => e
        ConfigCat.logger.error "threw exception #{e.class}:'#{e}'"
        ConfigCat.logger.error "stacktrace: #{e.backtrace}"
      end
    end

    def stop()
    end
  end

end

