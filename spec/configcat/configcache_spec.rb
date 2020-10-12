require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe ConfigCat::InMemoryConfigCache do
  it "test cache" do
    config_store = InMemoryConfigCache.new()

    value = config_store.get("key")
    expect(value).to be nil

    config_store.set("key", TEST_JSON)
    value = config_store.get("key")
    expect(value).to eq TEST_JSON

    value2 = config_store.get("key2")
    expect(value2).to be nil
  end

end
