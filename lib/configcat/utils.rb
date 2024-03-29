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

    def self.is_string_list(value)
      # Check if the value is an Array
      return false unless value.is_a?(Array)

      # Check if all elements in the Array are Strings
      value.each do |item|
        return false unless item.is_a?(String)
      end

      return true
    end
  end
end
