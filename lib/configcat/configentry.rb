require 'configcat/utils'

module ConfigCat

class ConfigEntry
  CONFIG = 'config'
  ETAG = 'etag'
  FETCH_TIME = 'fetch_time'

  attr_accessor :config, :etag, :fetch_time

  def initialize(config = {}, etag = '', fetch_time = DISTANT_PAST)
    @config = config
    @etag = etag
    @fetch_time = fetch_time
  end

  def self.create_from_json(json)
    return ConfigEntry.empty if json.nil?

    ConfigEntry.new(
      config: json.fetch(CONFIG, {}),
      etag: json.fetch(ETAG, ''),
      fetch_time: json.fetch(FETCH_TIME, DISTANT_PAST)
    )
  end

  def empty?
    self == ConfigEntry::EMPTY
  end

  def to_json
    {
      ETAG: etag,
      FETCH_TIME: fetch_time,
      CONFIG: config
    }
  end

  EMPTY = ConfigEntry.new
end

end
