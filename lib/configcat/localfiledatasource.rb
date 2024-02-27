require 'configcat/overridedatasource'
require 'configcat/config'


module ConfigCat
  class LocalFileFlagOverrides < FlagOverrides
    def initialize(file_path, override_behaviour)
      @file_path = file_path
      @override_behaviour = override_behaviour
    end

    def create_data_source(log)
      return LocalFileDataSource.new(@file_path, @override_behaviour, log)
    end
  end

  class LocalFileDataSource < OverrideDataSource
    def initialize(file_path, override_behaviour, log)
      super(override_behaviour)
      @log = log
      if !File.exist?(file_path)
        @log.error(1300, "Cannot find the local config file '#{file_path}'. This is a path that your application provided to the ConfigCat SDK by passing it to the `LocalFileFlagOverrides.new()` method. Read more: https://configcat.com/docs/sdk-reference/ruby/#json-file")
      end
      @_file_path = file_path
      @_config = nil
      @_cached_file_stamp = 0
    end

    def get_overrides
      reload_file_content()
      return @_config
    end

    private

    def reload_file_content
      begin
        stamp = File.mtime(@_file_path)
        if stamp != @_cached_file_stamp
          @_cached_file_stamp = stamp
          file = File.read(@_file_path)
          data = JSON.parse(file)
          if data.key?("flags")
            @_config = { FEATURE_FLAGS => {} }
            source = data["flags"]
            source.each do |key, value|
              value_type = case value
                           when true, false
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

              @_config[FEATURE_FLAGS][key] = { VALUE => { value_type => value } }
              setting_type = SettingType.from_type(value.class)
              @_config[FEATURE_FLAGS][key][SETTING_TYPE] = setting_type.to_i unless setting_type.nil?
            end
          else
            Config.extend_config_with_inline_salt_and_segment(data)
            @_config = data
          end
        end
      rescue JSON::ParserError => e
        @log.error(2302, "Failed to decode JSON from the local config file '#{@_file_path}'. #{e}")
      rescue Exception => e
        @log.error(1302, "Failed to read the local config file '#{@_file_path}'. #{e}")
      end
    end
  end
end
