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
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
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
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # Get value from Config Store, which doesn't indicate a config_fetcher call (cache)
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # Get value from Config Store, which indicates a config_fetcher call - 1 sec cache TTL
    sleep(1)
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
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
    settings, fetch_time = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1

    # assume 160 seconds has elapsed since the last call enough to do a
    allow(Time).to receive(:now).and_return(Time.at(fetch_time + 161))

    # Get value from Config Store, which indicates a config_fetcher call after cache invalidation
    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 2

    cache_policy.close
  end

  it "test_get_skips_hitting_api_after_update_from_different_thread" do
    config_fetcher = double("ConfigFetcher")
    successful_fetch_response = FetchResponse.success(ConfigEntry.new(JSON.parse(TEST_JSON)))
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
    cache_policy.get_settings
    expect(config_fetcher).to have_received(:get_configuration).once

    # when the cache timeout is still within the limit skip any network
    # requests, as this could be that multiple threads have attempted
    # to acquire the lock at the same time, but only really one needs to update

    successful_fetch_response.entry.fetch_time = now.utc.to_f - 159
    cache_policy.get_settings
    expect(config_fetcher).to have_received(:get_configuration).once

    successful_fetch_response.entry.fetch_time = now.utc.to_f - 161
    cache_policy.get_settings
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
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    cache_policy.close
  end

  it "test_return_cached_config_when_cache_is_not_expired" do
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: 1)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(
      {
        ConfigEntry::CONFIG => JSON.parse(TEST_JSON),
        ConfigEntry::ETAG => 'test-etag',
        ConfigEntry::FETCH_TIME => Utils.get_utc_now_seconds_since_epoch
      }.to_json
    )

    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    settings, _ = cache_policy.get_settings

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 0
    expect(config_fetcher.get_fetch_count).to eq 0

    sleep(1)

    settings, _ = cache_policy.get_settings

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
  end

  it "test_fetch_config_when_cache_is_expired" do
    cache_time_to_live_seconds = 1
    polling_mode = PollingMode.lazy_load(cache_refresh_interval_seconds: cache_time_to_live_seconds)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(
      {
        ConfigEntry::CONFIG => JSON.parse(TEST_JSON),
        ConfigEntry::ETAG => 'test-etag',
        ConfigEntry::FETCH_TIME => Utils.get_utc_now_seconds_since_epoch - cache_time_to_live_seconds
      }.to_json
    )

    hooks = Hooks.new
    logger = ConfigCatLogger.new(hooks)
    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, logger, config_cache, false)

    settings, _ = cache_policy.get_settings

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
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
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_offline
    expect(cache_policy.offline?).to be true

    sleep(1.5)

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
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
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    expect(stub_request).to have_been_made.times(0)

    sleep(1.5)

    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    expect(stub_request).to have_been_made.times(0)

    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.close
  end
end
