module ConfigCat

  class PollingMode
    def self.auto_poll(poll_interval_seconds: 60, max_init_wait_time_seconds: 5)
      poll_interval_seconds = 1 if poll_interval_seconds < 1
      max_init_wait_time_seconds = 0 if max_init_wait_time_seconds < 0

      AutoPollingMode.new(poll_interval_seconds, max_init_wait_time_seconds)
    end

    def self.lazy_load(cache_refresh_interval_seconds: 60)
      cache_refresh_interval_seconds = 1 if cache_refresh_interval_seconds < 1

      LazyLoadingMode.new(cache_refresh_interval_seconds)
    end

    def self.manual_poll
      ManualPollingMode.new
    end
  end

  class AutoPollingMode < PollingMode
    def initialize(poll_interval_seconds, max_init_wait_time_seconds)
      @poll_interval_seconds = poll_interval_seconds
      @max_init_wait_time_seconds = max_init_wait_time_seconds
    end

    def identifier
      return "a"
    end
  end

  class LazyLoadingMode < PollingMode
    def initialize(cache_refresh_interval_seconds)
      @cache_refresh_interval_seconds = cache_refresh_interval_seconds
    end

    def identifier
      return "l"
    end
  end

  class ManualPollingMode < PollingMode
    def identifier
      return "m"
    end
  end

end
