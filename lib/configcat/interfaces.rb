module ConfigCat

  class ConfigFetcher
    #
    #       Config fetcher interface
    #

    def get_configuration_json()
      #
      #     :return: Returns the configuration json Dictionary
      #
    end

    def close()
      #
      #         Closes the ConfigFetcher's resources
      #
    end
  end

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
