require 'spec_helper'

RSpec.describe 'Special character test', type: :feature do
  before(:all) do
    @client = ConfigCat.get('configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/u28_1qNyZ0Wz-ldYHIU7-g')
  end

  after(:all) do
    @client.close
  end

  it "test_special_characters_works_cleartext" do
    actual = @client.get_value("specialCharacters", "NOT_CAT", ConfigCat::User.new('äöüÄÖÜçéèñışğâ¢™✓😀'))
    expect(actual).to eq('äöüÄÖÜçéèñışğâ¢™✓😀')
  end

  it "test_special_characters_works_hashed" do
    actual = @client.get_value("specialCharactersHashed", "NOT_CAT", ConfigCat::User.new('äöüÄÖÜçéèñışğâ¢™✓😀'))
    expect(actual).to eq('äöüÄÖÜçéèñışğâ¢™✓😀')
  end

end
