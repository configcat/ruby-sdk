require 'spec_helper'
require 'configcat/configcatclient'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigCatClient do
  it "test_ensure_singleton_per_sdk_key" do
    client1 = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    client2 = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    expect(client1).to eq(client2)

    ConfigCatClient.close_all
    client1 = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    expect(client1).not_to eq(client2)

    ConfigCatClient.close_all
  end

  it "test_without_sdk_key" do
    expect {
      ConfigCatClient.new(nil)
    }.to raise_error(ConfigCatClientException)
  end

  it "test_bool" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_string" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testStringKey", "default")).to eq "testValue"
    client.close()
  end

  it "test_int" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testIntKey", 0)).to eq 1
    client.close()
  end

  it "test_double" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testDoubleKey", 0.0)).to eq 1.1
    client.close()
  end

  it "test_unknown" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testUnknownKey", "default")).to eq "default"
    client.close()
  end

  it "test_invalidation" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_get_all_keys" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(Set.new(client.get_all_keys())).to eq Set.new(["testBoolKey", "testStringKey", "testIntKey", "testDoubleKey", "key1", "key2"])
    client.close()
  end

  it "test_get_all_values" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    all_values = client.get_all_values()
    expect(all_values.size).to eq 6
    expect(all_values["testBoolKey"]).to eq true
    expect(all_values["testStringKey"]).to eq  "testValue"
    expect(all_values["testIntKey"]).to eq 1
    expect(all_values["testDoubleKey"]).to eq 1.1
    expect(all_values["key1"]).to eq true
    expect(all_values["key2"]).to eq false
    client.close()
  end

  it "test_get_all_value_details" do
    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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
    expect(details.variation_id).to eq 'fakeId1'

    details = details_by_key(all_details, 'key2')
    expect(details.key).to eq 'key2'
    expect(details.value).to eq false
    expect(details.variation_id).to eq 'fakeId2'

    client.close
  end

  it "test_get_value_details" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    client.force_refresh

    user = User.new("test@test1.com")
    details = client.get_value_details('testStringKey', '', user)

    expect(details.value).to eq('fake1')
    expect(details.key).to eq('testStringKey')
    expect(details.variation_id).to eq('id1')
    expect(details.is_default_value).to be_falsey
    expect(details.error).to be_nil
    expect(details.matched_evaluation_percentage_rule).to be_nil
    expect(details.matched_evaluation_rule[VALUE]).to eq('fake1')
    expect(details.matched_evaluation_rule[COMPARATOR]).to eq(2)
    expect(details.matched_evaluation_rule[COMPARISON_ATTRIBUTE]).to eq('Identifier')
    expect(details.matched_evaluation_rule[COMPARISON_VALUE]).to eq('@test1.com')
    expect(details.user.to_s).to eq(user.to_s)
    now = Utils.get_utc_now_seconds_since_epoch
    expect(now).to be >= details.fetch_time.to_f
    expect(now).to be <= details.fetch_time.to_f + 1

    client.close
  end

  it "test_default_user_get_value" do
    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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

  it "test_default_user_get_all_value" do
    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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
    expect(all_values['key2']).to be(false)

    all_values = client.get_all_values(user2)
    # Two dictionary should have exactly the same elements, order doesn't matter.
    expect(all_values.length).to eq(6)
    expect(all_values['testBoolKey']).to be(true)
    expect(all_values['testStringKey']).to eq('fake2')
    expect(all_values['testIntKey']).to eq(1)
    expect(all_values['testDoubleKey']).to eq(1.1)
    expect(all_values['key1']).to be(true)
    expect(all_values['key2']).to be(false)

    client.clear_default_user()
    all_values = client.get_all_values
    expect(all_values.length).to eq(6)
    expect(all_values['testBoolKey']).to be(true)
    expect(all_values['testStringKey']).to eq('testValue')
    expect(all_values['testIntKey']).to eq(1)
    expect(all_values['testDoubleKey']).to eq(1.1)
    expect(all_values['key1']).to be(true)
    expect(all_values['key2']).to be(false)

    client.close
  end

  it "test_default_user_get_variation_id" do
    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    user1 = User.new("test@test1.com")
    user2 = User.new("test@test2.com")

    client.set_default_user(user1)
    expect(client.get_variation_id("testStringKey", "")).to eq("id1")
    expect(client.get_variation_id("testStringKey", "", user2)).to eq("id2")

    client.clear_default_user
    expect(client.get_variation_id("testStringKey", "")).to eq("id")

    client.close
  end

  it "test_default_user_get_all_variation_ids" do
    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    user1 = User.new("test@test1.com")
    user2 = User.new("test@test2.com")

    client.set_default_user(user1)
    result = client.get_all_variation_ids
    expect(result.length).to eq(3)
    expect(result).to include('id1')
    expect(result).to include('fakeId1')
    expect(result).to include('fakeId2')

    result = client.get_all_variation_ids(user2)
    expect(result.length).to eq(3)
    expect(result).to include('id2')
    expect(result).to include('fakeId1')
    expect(result).to include('fakeId2')

    client.clear_default_user
    result = client.get_all_variation_ids
    expect(result.length).to eq(3)
    expect(result).to include('id')
    expect(result).to include('fakeId1')
    expect(result).to include('fakeId2')

    client.close
  end

  it "test_online_offline" do
    stub_request = WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))

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

    client = ConfigCatClient.get('test', ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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

  it "test_get_variation_id" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("key1", nil)).to eq "fakeId1"
    expect(client.get_variation_id("key2", nil)).to eq "fakeId2"
    client.close()
  end

  it "test_get_variation_id_not_found" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("nonexisting", "default_variation_id")).to eq "default_variation_id"
    client.close()
  end

  it "test_get_variation_id_empty_config" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("nonexisting", "default_variation_id")).to eq "default_variation_id"
    client.close()
  end

  it "test_get_all_variation_ids" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    result = client.get_all_variation_ids()
    expect(result.size).to eq 3
    expect(result.include?("fakeId1")).to eq true
    expect(result.include?("fakeId2")).to eq true
    client.close()
  end

  it "test_get_key_and_value" do
    client = ConfigCatClient.get("test", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                              config_cache: ConfigCacheMock.new))
    result = client.get_key_and_value("fakeId1")
    expect(result.key).to eq "key1"
    expect(result.value).to eq true
    result = client.get_key_and_value("fakeId2")
    expect(result.key).to eq "key2"
    expect(result.value).to eq false
    client.close()
  end
end
