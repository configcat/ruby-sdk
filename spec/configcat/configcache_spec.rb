require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe ConfigCat::InMemoryConfigCache do
  it "test_cache" do
    config_store = InMemoryConfigCache.new()

    value = config_store.get("key")
    expect(value).to be nil

    config_store.set("key", TEST_JSON)
    value = config_store.get("key")
    expect(value).to eq TEST_JSON

    value2 = config_store.get("key2")
    expect(value2).to be nil
  end

  it "test_cache_key" do
    expect(ConfigService.send(:get_cache_key, 'test1')).to eq('147c5b4c2b2d7c77e1605b1a4309f0ea6684a0c6')
    expect(ConfigService.send(:get_cache_key, 'test2')).to eq('c09513b1756de9e4bc48815ec7a142b2441ed4d5')
  end

  it "test_cache_payload" do
    now_seconds = 1686756435.8449
    etag = 'test-etag'
    entry = ConfigEntry.new(JSON.parse(TEST_JSON), etag, TEST_JSON, now_seconds)
    expect(entry.serialize).to eq('1686756435844' + "\n" + etag + "\n" + TEST_JSON)
  end

  it "tests_invalid_cache_content" do
    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new(on_error: hook_callbacks.method(:on_error))
    config_json_string = TEST_JSON_FORMAT % { value: '"test"' }
    config_cache = SingleValueConfigCache.new(ConfigEntry.new(
      JSON.parse(config_json_string),
      'test-etag',
      config_json_string,
      Utils.get_utc_now_seconds_since_epoch).serialize
    )

    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: config_cache,
                                                              hooks: hooks))

    expect(client.get_value('testKey', 'default')).to eq('test')
    expect(hook_callbacks.error_call_count).to eq(0)

    # Invalid fetch time in cache
    config_cache.value = ['text', 'test-etag', TEST_JSON_FORMAT % { value: '"test2"' }].join("\n")

    expect(client.get_value('testKey', 'default')).to eq('test')
    expect(hook_callbacks.error).to include('Error occurred while reading the cache. Invalid fetch time: text')

    # Number of values is fewer than expected
    config_cache.value = [Utils.get_utc_now_seconds_since_epoch.to_s, TEST_JSON_FORMAT % { value: '"test2"' }].join("\n")

    expect(client.get_value('testKey', 'default')).to eq('test')
    expect(hook_callbacks.error).to include('Error occurred while reading the cache. Number of values is fewer than expected.')

    # Invalid config JSON
    config_cache.value = [Utils.get_utc_now_seconds_since_epoch.to_s, 'test-etag', 'wrong-json'].join("\n")

    expect(client.get_value('testKey', 'default')).to eq('test')
    expect(hook_callbacks.error).to include('Error occurred while reading the cache. Invalid config JSON: wrong-json.')

    client.close
  end

end
