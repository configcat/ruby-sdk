require 'configcat/overridedatasource'
require 'configcat/constants'


module ConfigCat
  class LocalDictionaryDataSource < OverrideDataSource
    def initialize(source, override_behaviour)
      super(override_behaviour)
      dictionary = {}
      source.each do |key, value|
        dictionary[key] = {VALUE => value}
      end
      @_settings = {FEATURE_FLAGS => dictionary}
    end

    def get_overrides()
      return @_settings
    end
  end
end
