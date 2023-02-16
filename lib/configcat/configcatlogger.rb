module ConfigCat
  class ConfigCatLogger
    def initialize(hooks)
      @hooks = hooks
    end

    def debug(message)
      ConfigCat.logger.debug(message)
    end

    def info(message)
      ConfigCat.logger.info(message)
    end

    def warn(message)
      ConfigCat.logger.warn(message)
    end

    def error(message)
      @hooks.invoke_on_error(message)
      ConfigCat.logger.error(message)
    end
  end
end
