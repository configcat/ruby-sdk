require 'configcat/utils'

module ConfigCat
  class ConfigEntry
    CONFIG = 'config'
    ETAG = 'etag'
    FETCH_TIME = 'fetch_time'

    attr_accessor :config, :etag, :fetch_time

    def initialize(config = {}, etag = '', fetch_time = Utils::DISTANT_PAST)
      @config = config
      @etag = etag
      @fetch_time = fetch_time
    end

    def self.create_from_json(json)
      return ConfigEntry::EMPTY if json.nil?
      return ConfigEntry.new(
        config = json.fetch(CONFIG, {}),
        etag = json.fetch(ETAG, ''),
        fetch_time = json.fetch(FETCH_TIME, Utils::DISTANT_PAST)
      )
    end

    def empty?
      self == ConfigEntry::EMPTY
    end

    def to_json
      {
        CONFIG => config,
        ETAG => etag,
        FETCH_TIME => fetch_time
      }
    end

    EMPTY = ConfigEntry.new
  end
end
