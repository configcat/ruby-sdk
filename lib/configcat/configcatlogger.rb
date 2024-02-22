module ConfigCat
  class ConfigCatLogger
    def initialize(hooks)
      @hooks = hooks
    end

    def enabled_for?(log_level)
      ConfigCat.logger.level <= log_level
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
  end
end
