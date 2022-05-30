require 'spec_helper'

RSpec.describe ConfigCat do
  it "has a version number" do
    expect(ConfigCat::VERSION).not_to be nil
  end

  it "exposes ConfigCat::LocalDictionaryDataSource" do
    expect(ConfigCat::LocalDictionaryDataSource).not_to be nil
  end

  it "exposes ConfigCat::LocalFileDataSource" do
    expect(ConfigCat::LocalFileDataSource).not_to be nil
  end
end
