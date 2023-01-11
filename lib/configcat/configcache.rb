require 'configcat/interfaces'

module ConfigCat
  class NullConfigCache < ConfigCache
    def initialize
      @value = {}
    end

    def get(key)
      return nil
    end

    def set(key, value)
      # do nothing
    end
  end

  class InMemoryConfigCache < ConfigCache
    def initialize()
      @_value = {}
    end

    def get(key)
      return @_value.fetch(key, nil)
    end

    def set(key, value)
      @_value[key] = value
    end
  end
end
