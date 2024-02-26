require 'configcat/overridedatasource'
require 'configcat/config'


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
      @_config = {}
      source.each do |key, value|
        value_type = case value
                     when TrueClass, FalseClass
                       BOOL_VALUE
                     when String
                       STRING_VALUE
                     when Integer
                       INT_VALUE
                     when Float
                       DOUBLE_VALUE
                     else
                       UNSUPPORTED_VALUE
        end

        @_config[FEATURE_FLAGS] ||= {}
        @_config[FEATURE_FLAGS][key] = { VALUE => { value_type => value } }
        setting_type = SettingType.from_type(value.class)
        @_config[FEATURE_FLAGS][key][SETTING_TYPE] = setting_type.to_i unless setting_type.nil?
      end
    end

    def get_overrides
      return @_config
    end
  end
end
