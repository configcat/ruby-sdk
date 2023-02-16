module ConfigCat

  class PollingMode

    # Creates a configured auto polling configuration.
    #
    # :param poll_interval_seconds: sets at least how often this policy should fetch the latest configuration and refresh the cache.
    # :param max_init_wait_time_seconds: sets the maximum waiting time between initialization and the first config acquisition in seconds.
    # :return [AutoPollingMode]
    def self.auto_poll(poll_interval_seconds: 60, max_init_wait_time_seconds: 5)
      poll_interval_seconds = 1 if poll_interval_seconds < 1
      max_init_wait_time_seconds = 0 if max_init_wait_time_seconds < 0

      AutoPollingMode.new(poll_interval_seconds, max_init_wait_time_seconds)
    end

    # Creates a configured lazy loading polling configuration.
    #
    # :param cache_refresh_interval_seconds: sets how long the cache will store its value before fetching the latest from the network again.
    # :return [LazyLoadingMode]
    def self.lazy_load(cache_refresh_interval_seconds: 60)
      cache_refresh_interval_seconds = 1 if cache_refresh_interval_seconds < 1

      LazyLoadingMode.new(cache_refresh_interval_seconds)
    end

    # Creates a configured manual polling configuration.
    # :return [ManualPollingMode]
    def self.manual_poll
      ManualPollingMode.new
    end
  end

  class AutoPollingMode < PollingMode
    attr_reader :poll_interval_seconds, :max_init_wait_time_seconds

    def initialize(poll_interval_seconds, max_init_wait_time_seconds)
      @poll_interval_seconds = poll_interval_seconds
      @max_init_wait_time_seconds = max_init_wait_time_seconds
    end

    def identifier
      return "a"
    end
  end

  class LazyLoadingMode < PollingMode
    attr_reader :cache_refresh_interval_seconds

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
