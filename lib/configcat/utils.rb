module ConfigCat
  class Utils
    DISTANT_FUTURE = Float::INFINITY
    DISTANT_PAST = 0

    def self.get_utc_now_seconds_since_epoch
      return Time.now.utc.to_f
    end
  end
end
