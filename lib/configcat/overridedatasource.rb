module ConfigCat
  class OverrideBehaviour
    # When evaluating values, the SDK will not use feature flags & settings from the ConfigCat CDN, but it will use
    # all feature flags & settings that are loaded from local-override sources.
    LOCAL_ONLY = 0

    # When evaluating values, the SDK will use all feature flags & settings that are downloaded from the ConfigCat CDN,
    # plus all feature flags & settings that are loaded from local-override sources. If a feature flag or a setting is
    # defined both in the fetched and the local-override source then the local-override version will take precedence.
    LOCAL_OVER_REMOTE = 1

    # When evaluating values, the SDK will use all feature flags & settings that are downloaded from the ConfigCat CDN,
    # plus all feature flags & settings that are loaded from local-override sources. If a feature flag or a setting is
    # defined both in the fetched and the local-override source then the fetched version will take precedence.
    REMOTE_OVER_LOCAL = 2
  end

  class FlagOverrides
    # :returns [OverrideDataSource] the created OverrideDataSource
    def create_data_source(log)
    end
  end

  class OverrideDataSource
    def initialize(override_behaviour)
      @_override_behaviour = override_behaviour
    end

    def get_behaviour
      return @_override_behaviour
    end

    def get_overrides
      # :returns the override dictionary
      return {}
    end
  end
end
