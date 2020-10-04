require 'spec_helper'
require 'configcat/manualpollingcachepolicy'
require 'configcat/configcache'
require_relative 'mocks'

CACHE_KEY = "cache_key"

RSpec.describe ConfigCat::ManualPollingCachePolicy do
  it "test_without_refresh" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = ManualPollingCachePolicy.new(config_fetcher, config_cache, CACHE_KEY)
    value = cache_policy.get()
    expect(value).to be nil
    expect(config_fetcher.get_call_count).to eq 0
    cache_policy.stop()
  end
  it "test_with_refresh" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = ManualPollingCachePolicy.new(config_fetcher, config_cache, CACHE_KEY)
    cache_policy.force_refresh()
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 1
    cache_policy.stop()
  end
  it "test_with_refresh_httperror" do
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = InMemoryConfigCache.new()
    cache_policy = ManualPollingCachePolicy.new(config_fetcher, config_cache, CACHE_KEY)
    cache_policy.force_refresh()
    value = cache_policy.get()
    expect(value).to be nil
    cache_policy.stop()
  end
end
