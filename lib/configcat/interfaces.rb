module ConfigCat

  class ConfigCache
    #
    #       Config cache interface
    #

    def get(key)
      #
      #     :returns the config json object from the cache
      #
    end

    def set(key, value)
      #
      #     Sets the config json cache.
      #
    end
  end

  class CachePolicy
    #
    #       Config cache interface
    #

    def get()
      #
      #     :returns the config json object from the cache
      #
    end

    def force_refresh()
      #
      #
      #     :return:
      #
    end

    def stop()
      #
      #
      #     :return:
      #
    end
  end

  class ConfigCatClientException < Exception
    #
    #   Generic ConfigCatClientException
    #
  end

end
