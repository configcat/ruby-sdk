require 'configcat/interfaces'

module ConfigCat
  class InMemoryConfigCache < ConfigCache
    def initialize()
      @_value = nil
    end

    def get()
      return @_value
    end

    def set(value)
      @_value = value
    end
  end
end
