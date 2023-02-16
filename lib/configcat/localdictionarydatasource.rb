require 'configcat/overridedatasource'
require 'configcat/constants'


module ConfigCat
  class LocalDictionaryFlagOverrides < FlagOverrides
    def initialize(source, override_behaviour)
      @source = source
      @override_behaviour = override_behaviour
    end

    def create_data_source(log)
      return LocalDictionaryDataSource.new(@source, @override_behaviour)
    end
  end

  class LocalDictionaryDataSource < OverrideDataSource
    def initialize(source, override_behaviour)
      super(override_behaviour)
      @_settings = {}
      source.each do |key, value|
        @_settings[key] = {VALUE => value}
      end
    end

    def get_overrides
      return @_settings
    end
  end
end
