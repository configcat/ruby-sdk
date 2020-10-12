module ConfigCat
  class DataGovernance
    # Control the location of the config.json files containing your feature flags
    # and settings within the ConfigCat CDN.
    # Global: Select this if your feature flags are published to all global CDN nodes.
    # EuOnly: Select this if your feature flags are published to CDN nodes only in the EU.
    GLOBAL = 0
    EU_ONLY = 1
  end
end
