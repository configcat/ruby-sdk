require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'


RSpec.describe "LazyLoadingCachePolicy" do
  it "test_wrong_params" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 0)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    cache_policy.close
  end

  it "test_get" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    # Get value from Config Store, which indicates a config_fetcher call
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # Get value from Config Store, which doesn't indicate a config_fetcher call (cache)
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # Get value from Config Store, which indicates a config_fetcher call - 1 sec cache TTL
    sleep(1)
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 2

    cache_policy.close
  end

  it "test_refresh" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 160)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    # Get value from Config Store, which indicates a config_fetcher call
    config, fetch_time = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # assume 160 seconds has elapsed since the last call enough to do a force refresh
    allow(Time).to receive(:now).and_return(Time.at(fetch_time + 161))

    # Get value from Config Store, which indicates a config_fetcher call after cache invalidation
    cache_policy.refresh
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 2

    cache_policy.close
  end

  it "test_get_skips_hitting_api_after_update_from_different_thread" do
    config_fetcher = double("ConfigFetcher")
    successful_fetch_response = FetchResponse.success(ConfigEntry.new(JSON.parse(TEST_JSON), '', TEST_JSON))
    allow(config_fetcher).to receive(:get_configuration).and_return(successful_fetch_response)

    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 160)
    config_cache = NullConfigCache.new
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    now = Time.new(2020, 5, 20, 0, 0, 0, "+00:00")
    allow(Time).to receive(:now).and_return(now)
    successful_fetch_response.entry.fetch_time = now.utc.to_f

    # Get value from Config Store, which indicates a config_fetcher call
    cache_policy.get_config
    expect(config_fetcher).to have_received(:get_configuration).once

    # when the cache timeout is still within the limit skip any network
    # requests, as this could be that multiple threads have attempted
    # to acquire the lock at the same time, but only really one needs to update

    successful_fetch_response.entry.fetch_time = now.utc.to_f - 159
    cache_policy.get_config
    expect(config_fetcher).to have_received(:get_configuration).once

    successful_fetch_response.entry.fetch_time = now.utc.to_f - 161
    cache_policy.get_config
    expect(config_fetcher).to have_received(:get_configuration).twice
  end

  it "test_error" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 160)
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = InMemoryConfigCache.new()
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    # Get value from Config Store, which indicates a config_fetcher call
    config, _ = cache_policy.get_config
    expect(config).to be nil
    cache_policy.close
  end

  it "test_return_cached_config_when_cache_is_not_expired" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(ConfigEntry.new(
      JSON.parse(TEST_JSON),
      'test-etag',
      TEST_JSON,
      Utils.get_utc_now_seconds_since_epoch).serialize
    )

    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)

    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 0
    expect(config_fetcher.get_fetch_count).to eq 0

    sleep(1)

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)

    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
  end

  it "test_fetch_config_when_cache_is_expired" do
    cache_time_to_live_seconds = 1
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: cache_time_to_live_seconds)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(ConfigEntry.new(
      JSON.parse(TEST_JSON),
      'test-etag',
      TEST_JSON,
      Utils.get_utc_now_seconds_since_epoch - cache_time_to_live_seconds).serialize
    )

    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)

    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
  end

  it "test_cache_TTL_respects_external_cache" do
    WebMock.stub_request(:get, Regexp.new('https://.*'))
           .to_return(status: 200, body: TEST_JSON_FORMAT % { value_type: SettingType::STRING, value: '{"s": "test-remote"}' },
                      headers: {})

    config_json_string_local = TEST_JSON_FORMAT % { value_type: SettingType::STRING, value: '{"s": "test-local"}' }
    config_cache = SingleValueConfigCache.new(ConfigEntry.new(
      JSON.parse(config_json_string_local),
      'etag',
      config_json_string_local,
      Utils.get_utc_now_seconds_since_epoch).serialize
    )

    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    config_fetcher = ConfigFetcherMock.new
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)

    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "test-local"
    expect(config_fetcher.get_fetch_count).to eq 0

    sleep(1)

    config_json_string_local = TEST_JSON_FORMAT % { value_type: SettingType::STRING, value: '{"s": "test-local2"}' }
    config_cache.value = ConfigEntry.new(
      JSON.parse(config_json_string_local),
      'etag2',
      config_json_string_local,
      Utils.get_utc_now_seconds_since_epoch).serialize

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)

    expect(settings.fetch("testKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "test-local2"
    expect(config_fetcher.get_fetch_count).to eq 0
  end

  it "test_online_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    config_fetcher = ConfigFetcher.new("", logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    expect(cache_policy.offline?).to be false
    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testStringKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_offline
    expect(cache_policy.offline?).to be true

    sleep(1.5)

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testStringKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testStringKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(2)

    cache_policy.close
  end

  it "test_init_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    config_fetcher = ConfigFetcher.new("", logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, true)

    expect(cache_policy.offline?).to be true
    config, _ = cache_policy.get_config
    expect(config).to be nil
    expect(stub_request).to have_been_made.times(0)

    sleep(1.5)

    config, _ = cache_policy.get_config
    expect(config).to be nil
    expect(stub_request).to have_been_made.times(0)

    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    config, _ = cache_policy.get_config
    settings = config.fetch(FEATURE_FLAGS)
    expect(settings.fetch("testStringKey").fetch(VALUE).fetch(STRING_VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.close
  end
end
