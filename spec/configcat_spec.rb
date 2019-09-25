require "configcat"

RSpec.describe ConfigCat do
  it "has a version number" do
    expect(ConfigCat::VERSION).not_to be nil
  end
end
