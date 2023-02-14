module ConfigCat

  # Config cache interface
  class ConfigCache

    # :returns the config json object from the cache
    def get(key)
    end

    # Sets the config json cache.
    def set(key, value)
    end
  end

  # Generic ConfigCatClientException
  class ConfigCatClientException < Exception
  end

end
