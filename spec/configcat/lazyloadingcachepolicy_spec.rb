require 'configcat/lazyloadingcachepolicy'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe ConfigCat::LazyLoadingCachePolicy do
  it "test_wrong_params" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = LazyLoadingCachePolicy.new(config_fetcher, config_cache, 0)
    config = cache_policy.get()
    expect(config).to eq TEST_JSON
    cache_policy.stop()
  end
  it "test_cache" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = LazyLoadingCachePolicy.new(config_fetcher, config_cache, 1)
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 1
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 1
    sleep(1)
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 2
    cache_policy.stop()
  end
  it "test_force_refresh" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = LazyLoadingCachePolicy.new(config_fetcher, config_cache, 160)
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 1
    cache_policy.force_refresh()
    value = cache_policy.get()
    expect(value).to eq TEST_JSON
    expect(config_fetcher.get_call_count).to eq 2
    cache_policy.stop()
  end
  it "test_httperror" do
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = InMemoryConfigCache.new()
    cache_policy = LazyLoadingCachePolicy.new(config_fetcher, config_cache, 160)
    value = cache_policy.get()
    expect(value).to be nil
    cache_policy.stop()
  end
end
