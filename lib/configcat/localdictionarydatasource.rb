require 'configcat/overridedatasource'
require 'configcat/constants'


module ConfigCat
  class LocalDictionaryFlagOverrides < FlagOverrides
    def initialize(source, override_behaviour)
      @source = source
      @override_behaviour = override_behaviour
    end

    def create_data_source(log)
      LocalDictionaryDataSource.new(@source, @override_behaviour)
    end
  end

  class LocalDictionaryDataSource < OverrideDataSource
    def initialize(source, override_behaviour)
      super(override_behaviour)
      dictionary = {}
      source.each do |key, value|
        dictionary[key] = {VALUE => value}
      end
      @_settings = {FEATURE_FLAGS => dictionary}
    end

    def get_overrides
      return @_settings
    end
  end
end
