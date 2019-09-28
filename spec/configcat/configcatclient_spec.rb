require 'configcat/configcatclient'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigCatClient do
  it "test_without_api_key" do
    expect {
      ConfigCat::ConfigCatClient.new(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end
  it "test_bool" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testBoolKey", false)).to eq true
    client.stop()
  end
  it "test_string" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testStringKey", "default")).to eq "testValue"
    client.stop()
  end
  it "test_int" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testIntKey", 0)).to eq 1
    client.stop()
  end
  it "test_double" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testDoubleKey", 0.0)).to eq 1.1
    client.stop()
  end
  it "test_unknown" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testUnknownKey", "default")).to eq "default"
    client.stop()
  end
  it "test_invalidation" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(client.get_value("testBoolKey", false)).to eq true
    client.stop()
  end
  it "test_get_all_keys" do
    client = ConfigCat::ConfigCatClient.new("test", 0, 0, nil, 0, ConfigCacheMock)
    expect(Set.new(client.get_all_keys())).to eq Set.new(["testBoolKey", "testStringKey", "testIntKey", "testDoubleKey"])
    client.stop()
  end
end
