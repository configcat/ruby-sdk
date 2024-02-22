require 'configcat/utils'

module ConfigCat
  class ConfigEntry
    attr_accessor :config, :etag, :config_json_string, :fetch_time

    def initialize(config = {}, etag = '', config_json_string = '{}', fetch_time = Utils::DISTANT_PAST)
      @config = config
      @etag = etag
      @config_json_string = config_json_string
      @fetch_time = fetch_time
    end

    def empty?
      self == ConfigEntry::EMPTY
    end

    def serialize
      "#{(fetch_time * 1000).floor}\n#{etag}\n#{config_json_string}"
    end

    def self.create_from_string(string)
      return ConfigEntry.empty if string.nil? || string.empty?

      fetch_time_index = string.index("\n")
      etag_index = string.index("\n", fetch_time_index + 1)
      if fetch_time_index.nil? || etag_index.nil?
        raise 'Number of values is fewer than expected.'
      end

      begin
        fetch_time = Float(string[0...fetch_time_index])
      rescue ArgumentError
        raise "Invalid fetch time: #{string[0...fetch_time_index]}"
      end

      etag = string[fetch_time_index + 1...etag_index]
      if etag.nil? || etag.empty?
        raise 'Empty eTag value'
      end
      begin
        config_json = string[etag_index + 1..-1]
        config = JSON.parse(config_json)
        Config.extend_config_with_inline_salt_and_segment(config)
      rescue => e
        raise "Invalid config JSON: #{config_json}. #{e.message}"
      end

      ConfigEntry.new(config, etag, config_json, fetch_time / 1000.0)
    end

    EMPTY = ConfigEntry.new(etag: 'empty')
  end
end
