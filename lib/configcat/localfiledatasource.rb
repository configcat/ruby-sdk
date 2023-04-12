require 'configcat/overridedatasource'
require 'configcat/constants'


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
      if !File.exists?(file_path)
        @log.error(1300, "Cannot find the local config file '#{file_path}'. This is a path that your application provided to the ConfigCat SDK by passing it to the `LocalFileFlagOverrides.new()` method. Read more: https://configcat.com/docs/sdk-reference/ruby/#json-file")
      end
      @_file_path = file_path
      @_settings = nil
      @_cached_file_stamp = 0
    end

    def get_overrides
      reload_file_content()
      return @_settings
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
            @_settings = {}
            source = data["flags"]
            source.each do |key, value|
              @_settings[key] = { VALUE => value }
            end
          else
            @_settings = data[FEATURE_FLAGS]
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
