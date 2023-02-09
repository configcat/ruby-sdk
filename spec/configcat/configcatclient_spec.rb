require 'spec_helper'
require 'configcat/configcatclient'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigCatClient do
  it "test_without_sdk_key" do
    expect {
      ConfigCatClient.new(nil)
    }.to raise_error(ConfigCatClientException)
  end

  it "test_bool" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_string" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testStringKey", "default")).to eq "testValue"
    client.close()
  end

  it "test_int" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testIntKey", 0)).to eq 1
    client.close()
  end

  it "test_double" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testDoubleKey", 0.0)).to eq 1.1
    client.close()
  end

  it "test_unknown" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testUnknownKey", "default")).to eq "default"
    client.close()
  end

  it "test_invalidation" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_value("testBoolKey", false)).to eq true
    client.close()
  end

  it "test_get_all_keys" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(Set.new(client.get_all_keys())).to eq Set.new(["testBoolKey", "testStringKey", "testIntKey", "testDoubleKey", "key1", "key2"])
    client.close()
  end

  it "test_get_all_values" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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

  it "test_get_variation_id" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("key1", nil)).to eq "fakeId1"
    expect(client.get_variation_id("key2", nil)).to eq "fakeId2"
    client.close()
  end

  it "test_get_variation_id_not_found" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("nonexisting", "default_variation_id")).to eq "default_variation_id"
    client.close()
  end

  it "test_get_variation_id_empty_config" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    expect(client.get_variation_id("nonexisting", "default_variation_id")).to eq "default_variation_id"
    client.close()
  end

  it "test_get_all_variation_ids" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                       config_cache: ConfigCacheMock.new))
    result = client.get_all_variation_ids()
    expect(result.size).to eq 2
    expect(result.include?("fakeId1")).to eq true
    expect(result.include?("fakeId2")).to eq true
    client.close()
  end

  it "test_get_key_and_value" do
    client = ConfigCatClient.get("test", options: ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
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
