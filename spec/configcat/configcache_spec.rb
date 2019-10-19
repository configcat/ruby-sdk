require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe ConfigCat::InMemoryConfigCache do
  it "test cache" do
    config_store = InMemoryConfigCache.new()
    value = config_store.get()
    expect(value).to be nil
    config_store.set(TEST_JSON)
    value = config_store.get()
    expect(value).to eq TEST_JSON
  end

end
