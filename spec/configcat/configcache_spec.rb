require 'configcat/configcache'

TEST_JSON = '{"testKey": { "Value": "testValue", "SettingType": 1, ' \
            '"PercentageRolloutItems": [], "TargetedRolloutRules": [] }}'

RSpec.describe ConfigCat::InMemoryConfigCache do
  it "test cache" do
    config_store = ConfigCat::InMemoryConfigCache.new()
    value = config_store.get()
    expect(value).to be nil
    config_store.set(TEST_JSON)
    value = config_store.get()
    expect(value).to eq TEST_JSON
  end

end
