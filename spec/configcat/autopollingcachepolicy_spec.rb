require 'configcat/autopollingcachepolicy'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe ConfigCat::AutoPollingCachePolicy do
  it "test_wrong_params" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 0, -1, nil)
    sleep(2)
    config = cache_policy.get()
    expect(config).to eq TEST_JSON
    cache_policy.stop()
  end
  it "test_init_wait_time_ok" do
    config_fetcher = ConfigFetcherWaitMock.new(0)
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 60, 5, nil)
    config = cache_policy.get()
    expect(config).to eq TEST_JSON
    cache_policy.stop()
  end
  it "test_init_wait_time_timeout" do
    config_fetcher = ConfigFetcherWaitMock.new(5)
    config_cache = InMemoryConfigCache.new()
    start_time = Time.now.utc
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 60, 1, nil)
    config = cache_policy.get()
    end_time = Time.now.utc
    elapsed_time = end_time - start_time
    expect(config).to be nil
    expect(elapsed_time).to be > 1
    expect(elapsed_time).to be < 2
    cache_policy.stop()
  end
  it "test_fetch_call_count" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 2, 1, nil)
    sleep(3)
    expect(config_fetcher.get_call_count).to eq 2
    config = cache_policy.get()
    expect(config).to eq TEST_JSON
    cache_policy.stop()
  end
  it "test_updated_values" do
    config_fetcher = ConfigFetcherCountMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 2, 5, nil)
    config = cache_policy.get()
    expect(config).to eq 10
    sleep(2.2)
    config = cache_policy.get()
    expect(config).to eq 20
    cache_policy.stop()
  end
  it "test_http_error" do
    config_fetcher = ConfigFetcherWithErrorMock.new(StandardError.new("error"))
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 60, 1)
    value = cache_policy.get()
    expect(value).to be nil
    cache_policy.stop()
  end
  it "test_stop" do
    config_fetcher = ConfigFetcherCountMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 2, 5, nil)
    cache_policy.stop()
    config = cache_policy.get()
    expect(config).to eq 10
    sleep(2.2)
    config = cache_policy.get()
    expect(config).to eq 10
    cache_policy.stop()
  end
  it "test_rerun" do
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 2, 5, nil)
    sleep(2.2)
    expect(config_fetcher.get_call_count).to eq 2
    cache_policy.stop()
  end
  it "test_callback" do
    call_counter = CallCounter.new()
    config_fetcher = ConfigFetcherMock.new()
    config_cache = InMemoryConfigCache.new()
    cache_policy = AutoPollingCachePolicy.new(config_fetcher, config_cache, 2, 5, call_counter.method(:callback))
    sleep(1)
    expect(config_fetcher.get_call_count).to eq 1
    expect(call_counter.get_call_count).to eq 1
    sleep(1.2)
    expect(config_fetcher.get_call_count).to eq 2
    expect(call_counter.get_call_count).to eq 1
    config_fetcher.set_configuration_json(TEST_JSON2)
    sleep(2.2)
    expect(config_fetcher.get_call_count).to eq 3
    expect(call_counter.get_call_count).to eq 2
    cache_policy.stop()
  end
end
