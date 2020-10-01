require 'configcat/interfaces'

module ConfigCat
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
