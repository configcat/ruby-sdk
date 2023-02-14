require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe "ManualPollingCachePolicy" do
  before(:each) do
    WebMock.reset!
  end

  it "test_without_refresh" do
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", PollingMode.manual_poll, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    expect(config_fetcher.get_call_count).to eq 0
    cache_policy.close
  end

  it "test_with_refresh" do
    config_fetcher = ConfigFetcherMock.new
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", PollingMode.manual_poll, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "testValue"
    expect(config_fetcher.get_call_count).to eq 1
    cache_policy.close
  end

  it "test_with_refresh_error" do
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = InMemoryConfigCache.new
    cache_policy = ConfigService.new('', PollingMode.manual_poll, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)
    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings).to be nil
    cache_policy.close
  end

  it "test_with_failed_refresh" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.manual_poll
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"

    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 500, body: "", headers: {})

    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"

    cache_policy.close
  end

  it "test_cache" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*'))
                     .to_return(status: 200, body: TEST_JSON_FORMAT % {value: '"test"'}, headers: {})

    polling_mode = PollingMode.manual_poll
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = InMemoryConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "test"
    expect(stub_request).to have_been_made.times(1)
    expect(config_cache.value.length).to eq 1

    WebMock.stub_request(:get, Regexp.new('https://.*'))
           .to_return(status: 200, body: TEST_JSON_FORMAT % {value: '"test2"'}, headers: {})

    cache_policy.refresh
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testKey").fetch(VALUE)).to eq "test2"
    expect(stub_request).to have_been_made.times(2)
    expect(config_cache.value.length).to eq 1

    cache_policy.close
  end

  it "test_online_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.manual_poll
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, false)

    expect(cache_policy.offline?).to be false
    expect(cache_policy.refresh.success).to be true
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_offline

    expect(cache_policy.offline?).to be true
    expect(cache_policy.refresh.success).to be false
    expect(stub_request).to have_been_made.times(1)

    cache_policy.set_online

    expect(cache_policy.offline?).to be false
    expect(cache_policy.refresh.success).to be true
    expect(stub_request).to have_been_made.times(2)

    cache_policy.close
  end

  it "test_init_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    polling_mode = PollingMode.manual_poll
    config_fetcher = ConfigFetcher.new("", ConfigCat.logger, polling_mode.identifier())
    config_cache = NullConfigCache.new
    cache_policy = ConfigService.new("", polling_mode, Hooks.new, config_fetcher, ConfigCat.logger, config_cache, true)

    expect(cache_policy.offline?).to be true
    expect(cache_policy.refresh.success).to be false
    expect(stub_request).to have_been_made.times(0)

    cache_policy.set_online

    expect(cache_policy.offline?).to be false
    expect(cache_policy.refresh.success).to be true
    settings, _ = cache_policy.get_settings
    expect(settings.fetch("testStringKey").fetch(VALUE)).to eq "testValue"
    expect(stub_request).to have_been_made.times(1)

    cache_policy.close
  end

end
