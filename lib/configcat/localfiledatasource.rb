require 'configcat/overridedatasource'
require 'configcat/constants'


module ConfigCat
  class LocalFileDataSource < OverrideDataSource
    def initialize(file_path, override_behaviour)
      super(override_behaviour)
      if File.exists?(file_path)
        ConfigCat.logger.error("The file '%s' does not exists." % file_path)
      end
      @_file_path = file_path
      @_settings = nil
      @_cached_file_stamp = 0
    end

    def get_overrides()
      reload_file_content()
      return @_settings
    end

    private

    def reload_file_content()
      begin
        stamp = File.mtime(@_file_path)
        if stamp != @_cached_file_stamp
          @_cached_file_stamp = stamp
          file = File.read(@_file_path)
          data = JSON.parse(file)
          if data.key?("flags")
            dictionary = {}
            source = data["flags"]
            source.each do |key, value|
              dictionary[key] = {VALUE => value}
            end
            @_settings = {FEATURE_FLAGS => dictionary}
          else
            @_settings = data
          end
        end
      rescue JSON::ParserError => e
        ConfigCat.logger.error("Could not decode json from file %s. %s" % [@_file_path, e.to_s])
      rescue Exception => e
        ConfigCat.logger.error("Could not read the content of the file %s. %s" % [@_file_path, e.to_s])
      end
    end
  end
end
