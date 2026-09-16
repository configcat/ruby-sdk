module ConfigCat
  class ConfigCatLogger
    def self.mask_sdk_key(sdk_key)
      num_chars_to_keep = 6
      return sdk_key if sdk_key.length <= num_chars_to_keep

      sdk_key[0, sdk_key.length - num_chars_to_keep].gsub(%r{[^/]}, '*') + sdk_key[-num_chars_to_keep, num_chars_to_keep]
    end

    def initialize(hooks)
      @hooks = hooks
    end

    def enabled_for?(log_level)
      coerce_log_level(ConfigCat.logger.level) <= log_level
    end

    def debug(message)
      ConfigCat.logger.debug("[0] " + message)
    end

    def info(event_id, message)
      ConfigCat.logger.info("[" + event_id.to_s + "] " + message)
    end

    def warn(event_id, message)
      ConfigCat.logger.warn("[" + event_id.to_s + "] " + message)
    end

    def error(event_id, message)
      @hooks.invoke_on_error(message)
      ConfigCat.logger.error("[" + event_id.to_s + "] " + message)
    end
    private

    def coerce_log_level(level)
      return level if level.is_a?(Integer)

      case level.to_s.downcase
      when 'trace', 'debug'
        ::Logger::DEBUG
      when 'info'
        ::Logger::INFO
      when 'warn'
        ::Logger::WARN
      when 'error'
        ::Logger::ERROR
      when 'fatal'
        ::Logger::FATAL
      when 'unknown'
        ::Logger::UNKNOWN
      else
        raise ArgumentError, "invalid log level: #{level}"
      end
    end
  end
end
