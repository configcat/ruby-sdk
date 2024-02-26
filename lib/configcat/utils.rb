module ConfigCat
  class Utils
    DISTANT_FUTURE = Float::INFINITY
    DISTANT_PAST = 0

    def self.get_date_time(seconds_since_epoch)
      Time.at(seconds_since_epoch).utc
    end

    def self.get_utc_now_seconds_since_epoch
      Time.now.utc.to_f
    end

    def self.get_seconds_since_epoch(date_time)
      date_time.to_time.to_f
    end
  end
end
