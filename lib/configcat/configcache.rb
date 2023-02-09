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
    attr_reader :value
    def initialize
      @value = {}
    end

    def get(key)
      return @value.fetch(key, nil)
    end

    def set(key, value)
      @value[key] = value
    end
  end
end
