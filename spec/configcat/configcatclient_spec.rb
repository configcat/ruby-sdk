require 'spec_helper'
require 'configcat/configcatclient'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigCatClient do
  it "test_ensure_singleton_per_sdk_key" do
    client1 = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    client2 = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    expect(client1).to eq(client2)

    ConfigCatClient.close_all
    client1 = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    expect(client1).not_to eq(client2)

    ConfigCatClient.close_all
  end

  it "test_without_sdk_key" do
    expect {
      ConfigCatClient.new(nil)
    }.to raise_error(ConfigCatClientException)
  end

  [
    ["sdk-key-90123456789012", false, false],
    ["sdk-key-9012345678901/1234567890123456789012", false, false],
    ["sdk-key-90123456789012/123456789012345678901", false, false],
    ["sdk-key-90123456789012/12345678901234567890123", false, false],
    ["sdk-key-901234567890123/1234567890123456789012", false, false],
    ["sdk-key-90123456789012/1234567890123456789012", false, true],
    ["configcat-sdk-1/sdk-key-90123456789012", false, false],
    ["configcat-sdk-1/sdk-key-9012345678901/1234567890123456789012", false, false],
    ["configcat-sdk-1/sdk-key-90123456789012/123456789012345678901", false, false],
    ["configcat-sdk-1/sdk-key-90123456789012/12345678901234567890123", false, false],
    ["configcat-sdk-1/sdk-key-901234567890123/1234567890123456789012", false, false],
    ["configcat-sdk-1/sdk-key-90123456789012/1234567890123456789012", false, true],
    ["configcat-sdk-2/sdk-key-90123456789012/1234567890123456789012", false, false],
    ["configcat-proxy/", false, false],
    ["configcat-proxy/", true, false],
    ["configcat-proxy/sdk-key-90123456789012", false, false],
    ["configcat-proxy/sdk-key-90123456789012", true, true],
  ].each do |sdk_key, custom_base_url, is_valid|
    it "test_sdk_key_format_validation (#{sdk_key}, #{custom_base_url}, #{is_valid})" do
      if custom_base_url
        base_url = 'https://my-configcat-proxy'
      else
        base_url = nil
      end

      begin
        ConfigCatClient.get(sdk_key, ConfigCatOptions.new(base_url: base_url))
        expect(is_valid).to eq(true)
      rescue ConfigCatClientException => e
        expect(is_valid).to eq(false)
      end
    end
  end

  it "test_bool" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_string" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testStringKey", "default")).to eq "testValue"
    client.close()
  end

  it "test_int" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testIntKey", 0)).to eq 1
    client.close()
  end

  it "test_double" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testDoubleKey", 0.0)).to eq 1.1
    client.close()
  end

  it "test_unknown" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testUnknownKey", "default")).to eq "default"
    client.close()
  end

  it "test_invalidation" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_incorrect_json" do
    config_json_string = '{
      "f": {
        "testKey":  {
          "t": 0,
          "r": [ {
            "c": [ { "u": { "a": "Custom1", "c": 19, "d": "wrong_utc_timestamp" } } ],
            "s": { "v": { "b": true } }
          } ],
          "v": { "b": false }
        }
      }
    }'
    config_cache = SingleValueConfigCache.new(ConfigEntry.new(
      JSON.parse(config_json_string),
      'test-etag',
      config_json_string,
      Utils.get_utc_now_seconds_since_epoch).serialize
    )


    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new(on_error: hook_callbacks.method(:on_error))
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: config_cache,
                                                                    hooks: hooks))

    expect(client.get_value('testKey', false, User.new('1234', custom: {'Custom1' => 1681118000.56}))).to eq(false)
    expect(hook_callbacks.error_call_count).to eq(1)
    expect(hook_callbacks.error).to include("Failed to evaluate setting 'testKey'.")
    client.close
  end

  it "test_get_all_keys" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(Set.new(client.get_all_keys())).to eq Set.new(["testBoolKey", "testStringKey", "testIntKey", "testDoubleKey", "key1", "key2"])
    client.close()
  end

  it "test_get_all_values" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    all_values = client.get_all_values()
    expect(all_values.size).to eq 6
    expect(all_values["testBoolKey"]).to eq true
    expect(all_values["testStringKey"]).to eq "testValue"
    expect(all_values["testIntKey"]).to eq 1
    expect(all_values["testDoubleKey"]).to eq 1.1
    expect(all_values["key1"]).to eq true
    expect(all_values["key2"]).to eq "fake4"
    client.close()
  end

  it "test_get_all_value_details" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    all_details = client.get_all_value_details

    def details_by_key(all_details, key)
      all_details.each do |details|
        return details if details.key == key
      end
      nil
    end

    expect(all_details.length).to eq 6

    details = details_by_key(all_details, 'testBoolKey')
    expect(details.key).to eq 'testBoolKey'
    expect(details.value).to eq true

    details = details_by_key(all_details, 'testStringKey')
    expect(details.key).to eq 'testStringKey'
    expect(details.value).to eq 'testValue'
    expect(details.variation_id).to eq 'id'

    details = details_by_key(all_details, 'testIntKey')
    expect(details.key).to eq 'testIntKey'
    expect(details.value).to eq 1

    details = details_by_key(all_details, 'testDoubleKey')
    expect(details.key).to eq 'testDoubleKey'
    expect(details.value).to eq 1.1

    details = details_by_key(all_details, 'key1')
    expect(details.key).to eq 'key1'
    expect(details.value).to eq true
    expect(details.variation_id).to eq 'id3'

    details = details_by_key(all_details, 'key2')
    expect(details.key).to eq 'key2'
    expect(details.value).to eq 'fake4'
    expect(details.variation_id).to eq 'id4'

    client.close
  end

  it "test_get_value_details" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    client.force_refresh

    user = User.new("test@test1.com")
    details = client.get_value_details('testStringKey', '', user)

    expect(details.value).to eq('fake1')
    expect(details.key).to eq('testStringKey')
    expect(details.variation_id).to eq('id1')
    expect(details.is_default_value).to be_falsey
    expect(details.error).to be_nil
    expect(details.matched_percentage_option).to be_nil
    expect(details.matched_targeting_rule[SERVED_VALUE][VALUE][STRING_VALUE]).to eq('fake1')
    expect(details.user.to_s).to eq(user.to_s)
    now = Utils.get_utc_now_seconds_since_epoch
    expect(now).to be >= details.fetch_time.to_f
    expect(now).to be <= details.fetch_time.to_f + 1

    client.close
  end

  it "test_default_user_get_value" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    user1 = User.new("test@test1.com")
    user2 = User.new("test@test2.com")

    client.set_default_user(user1)
    expect(client.get_value("testStringKey", "")).to eq("fake1")
    expect(client.get_value("testStringKey", "", user2)).to eq("fake2")

    client.clear_default_user
    expect(client.get_value("testStringKey", "")).to eq("testValue")

    client.close
  end

  it "test_default_user_get_all_values" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    user1 = User.new("test@test1.com")
    user2 = User.new("test@test2.com")

    client.set_default_user(user1)
    all_values = client.get_all_values
    # Two dictionary should have exactly the same elements, order doesn't matter.
    expect(all_values.length).to eq(6)
    expect(all_values['testBoolKey']).to be(true)
    expect(all_values['testStringKey']).to eq('fake1')
    expect(all_values['testIntKey']).to eq(1)
    expect(all_values['testDoubleKey']).to eq(1.1)
    expect(all_values['key1']).to be(true)
    expect(all_values['key2']).to eq('fake6')

    all_values = client.get_all_values(user2)
    # Two dictionary should have exactly the same elements, order doesn't matter.
    expect(all_values.length).to eq(6)
    expect(all_values['testBoolKey']).to be(true)
    expect(all_values['testStringKey']).to eq('fake2')
    expect(all_values['testIntKey']).to eq(1)
    expect(all_values['testDoubleKey']).to eq(1.1)
    expect(all_values['key1']).to be(true)
    expect(all_values['key2']).to eq('fake8')

    client.clear_default_user()
    all_values = client.get_all_values
    expect(all_values.length).to eq(6)
    expect(all_values['testBoolKey']).to be(true)
    expect(all_values['testStringKey']).to eq('testValue')
    expect(all_values['testIntKey']).to eq(1)
    expect(all_values['testDoubleKey']).to eq(1.1)
    expect(all_values['key1']).to be(true)
    expect(all_values['key2']).to eq('fake4')

    client.close
  end

  it "test_online_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))

    expect(client.offline?).to be false

    client.force_refresh

    expect(stub_request).to have_been_made.times(1)

    client.set_offline
    expect(client.offline?).to be true

    client.force_refresh

    expect(stub_request).to have_been_made.times(1)

    client.set_online
    expect(client.offline?).to be false

    client.force_refresh

    expect(stub_request).to have_been_made.times(2)

    client.close
  end

  it "test_init_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    offline: true))

    expect(client.offline?).to be true

    client.force_refresh

    expect(stub_request).to have_been_made.times(0)

    client.set_online
    expect(client.offline?).to be false

    client.force_refresh

    expect(stub_request).to have_been_made.times(1)

    client.close
  end

  # variation id tests

  it "test_get_variation_id" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value_details("key1", nil).variation_id).to eq "id3"
    expect(client.get_value_details("key2", nil).variation_id).to eq "id4"
    client.close()
  end

  it "test_get_variation_id_not_found" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value_details("nonexisting", "default_value").variation_id).to be_nil
    client.close()
  end

  it "test_get_variation_id_empty_config" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    expect(client.get_value_details("nonexisting", "default_value").variation_id).to be_nil
    client.close()
  end

  it "test_get_key_and_value" do
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: ConfigCacheMock.new))
    result = client.get_key_and_value("id1")
    expect(result.key).to eq "testStringKey"
    expect(result.value).to eq "fake1"

    result = client.get_key_and_value("id2")
    expect(result.key).to eq "testStringKey"
    expect(result.value).to eq "fake2"

    result = client.get_key_and_value("id3")
    expect(result.key).to eq "key1"
    expect(result.value).to eq true

    result = client.get_key_and_value("id4")
    expect(result.key).to eq "key2"
    expect(result.value).to eq "fake4"

    result = client.get_key_and_value("id5")
    expect(result.key).to eq "key2"
    expect(result.value).to eq "fake5"

    result = client.get_key_and_value("id6")
    expect(result.key).to eq "key2"
    expect(result.value).to eq "fake6"

    result = client.get_key_and_value("id7")
    expect(result.key).to eq "key2"
    expect(result.value).to eq "fake7"

    result = client.get_key_and_value("id8")
    expect(result.key).to eq "key2"
    expect(result.value).to eq "fake8"

    client.close()
  end
end
