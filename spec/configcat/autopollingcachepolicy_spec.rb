require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'


RSpec.describe "AutoPollingCachePolicy" do
  it "test_wrong_params" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 0,
                                         max_init_wait_time_seconds: -1)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    sleep(2)
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    cache_policy.close
  end

  it "test_init_wait_time_ok" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 60,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherWaitMock.new(0)
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    cache_policy.close
  end

  it "test_init_wait_time_timeout" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 60,
                                         max_init_wait_time_seconds: 1)
    config_fetcher = ConfigFetcherWaitMock.new(5)
    config_cache = NullConfigCache.new
    start_time = Time.now.utc
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    settings, _ = cache_policy.get_settings
    end_time = Time.now.utc
    elapsed_time = end_time - start_time
    expect(settings).to be nil
    expect(elapsed_time).to be > 1
    expect(elapsed_time).to be < 2
    cache_policy.close
  end

  it "test_fetch_call_count" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 1)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    sleep(3)
    expect(config_fetcher.get_call_count).to eq 2
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    cache_policy.close
  end

  it "test_updated_values" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherCountMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq 1

    sleep(2.2)

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq 2

    cache_policy.close
  end

  it "test_error" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 60,
                                         max_init_wait_time_seconds: 1)
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    # Get value from Config Store, which indicates a config_fetcher call
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    cache_policy.close
  end

  it "test_close" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherCountMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    cache_policy.close
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq 1
    sleep(2.2)
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq 1
    cache_policy.close
  end

  it "test_rerun" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    sleep(2.2)
    expect(config_fetcher.get_call_count).to eq 2
    cache_policy.close
  end

  it "test_callback" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new
    hooks.add_on_config_changed(hook_callbacks.method(:on_config_changed))

    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, ConfigCat.logger, config_cache, false)

    sleep(1)
    expect(config_fetcher.get_call_count).to eq 1
    expect(hook_callbacks.changed_config_call_count).to eq 1
    sleep(1.2)
    expect(config_fetcher.get_call_count).to eq 2
    expect(hook_callbacks.changed_config_call_count).to eq 1
    config_fetcher.set_configuration_json(TEST_JSON2)
    sleep(2.2)
    expect(config_fetcher.get_call_count).to eq 3
    expect(hook_callbacks.changed_config_call_count).to eq 2
    cache_policy.close
  end

  it "test_callback_exception" do
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 2,
                                         max_init_wait_time_seconds: 5)
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new
    hooks.add_on_config_changed(hook_callbacks.method(:callback_exception))

    cache_policy = ConfigService.new("", polling_mode, hooks, config_fetcher, ConfigCat.logger, config_cache, false)

    sleep(1)
    expect(config_fetcher.get_call_count).to eq 1
    expect(hook_callbacks.callback_exception_call_count).to eq 1
    sleep(1.2)
    expect(config_fetcher.get_call_count).to eq 2
    expect(hook_callbacks.callback_exception_call_count).to eq 1
    config_fetcher.set_configuration_json(TEST_JSON2)
    sleep(2.2)
    expect(config_fetcher.get_call_count).to eq 3
    expect(hook_callbacks.callback_exception_call_count).to eq 2
    cache_policy.close
  end

  it "test_with_failed_refresh" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 1)
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    # first call
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"

    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 500, body: "", headers: {})

    # wait for cache invalidation
    sleep(1.5)

    # previous value returned because of the refresh failure
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"

    cache_policy.close
  end

  it "test_return_cached_config_when_cache_is_not_expired" do
    poll_interval_seconds = 2
    max_init_wait_time_seconds = 1
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: poll_interval_seconds,
                                         max_init_wait_time_seconds: max_init_wait_time_seconds)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(
      {
        ConfigEntry::CONFIG => JSON.parse(TEST_JSON),
        ConfigEntry::ETAG => 'test-etag',
        ConfigEntry::FETCH_TIME => Utils.get_utc_now_seconds_since_epoch
      }.to_json
    )

    start_time = Time.now.utc
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    settings, _ = cache_policy.get_settings
    end_time = Time.now.utc
    elapsed_time = end_time - start_time

    # max init wait time should be ignored when cache is not expired
    expect(elapsed_time).to be <= max_init_wait_time_seconds

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 0
    expect(config_fetcher.get_fetch_count).to eq 0

    sleep(3)

    settings, _ = cache_policy.get_settings

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
  end

  it "test_fetch_config_when_cache_is_expired" do
    poll_interval_seconds = 2
    max_init_wait_time_seconds = 1
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: poll_interval_seconds,
                                         max_init_wait_time_seconds: max_init_wait_time_seconds)
    config_fetcher = ConfigFetcherMock.new
    config_cache = SingleValueConfigCache.new(
      {
        ConfigEntry::CONFIG => JSON.parse(TEST_JSON),
        ConfigEntry::ETAG => 'test-etag',
        ConfigEntry::FETCH_TIME => Utils.get_utc_now_seconds_since_epoch - poll_interval_seconds
      }.to_json
    )

    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    settings, _ = cache_policy.get_settings

    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    expect(config_fetcher.get_fetch_count).to eq 1

    cache_policy.close
  end

  it "test_init_wait_time_return_cached" do
    poll_interval_seconds = 60
    max_init_wait_time_seconds = 1
    polling_mode = PollingMode.auto_poll(poll_interval_seconds: poll_interval_seconds,
                                         max_init_wait_time_seconds: max_init_wait_time_seconds)
    config_fetcher = ConfigFetcherWaitMock.new(5)
    config_cache = SingleValueConfigCache.new(
      {
        ConfigEntry::CONFIG => JSON.parse(TEST_JSON2),
        ConfigEntry::ETAG => 'test-etag',
        ConfigEntry::FETCH_TIME => Utils.get_utc_now_seconds_since_epoch - 2 * poll_interval_seconds
      }.to_json
    )

    start_time = Time.now.utc
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    settings, _ = cache_policy.get_settings
    end_time = Time.now.utc
    elapsed_time = end_time - start_time

    expect(elapsed_time).to be > max_init_wait_time_seconds
    expect(elapsed_time).to be < max_init_wait_time_seconds + 1
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(settings.fetch("testKey2").fetch(VALUE)).to eq "testValue2"

    cache_policy.close
  end

  it "test_online_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 1)
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    expect(cache_policy.offline?).to be false

    sleep(1.5)

    cache_policy.set_offline
    expect(cache_policy.offline?).to be true
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(2)

    sleep(2)

    expect(stub_request).to have_been_made.times(2)
    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    sleep(1)

    expect(stub_request).to have_been_made.at_least_twice
    cache_policy.close
  end

  it "test_init_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.auto_poll(poll_interval_seconds: 1)
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, true)

    expect(cache_policy.offline?).to be true
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    expect(stub_request).to have_been_made.times(0)

    sleep(2)

    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    expect(stub_request).to have_been_made.times(0)

    cache_policy.set_online
    expect(cache_policy.offline?).to be false

    sleep(2.5)

    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.at_least_twice

    cache_policy.close
  end
end
