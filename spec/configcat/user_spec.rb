require 'spec_helper'
require 'configcat/user'
require_relative 'mocks'

RSpec.describe ConfigCat::User do
  it "test_empty_or_none_identifier" do
    u1 = User.new(nil)
    expect(u1.get_identifier()).to eq ""
    u2 = User.new("")
    expect(u2.get_identifier()).to eq ""
  end

  it "test_attribute_case_sensitivity" do
    user_id = "id"
    email = "test@test.com"
    country = "country"
    custom = { 'custom' => 'test' }
    user = User.new(user_id, email: email, country: country, custom: custom)

    expect(user.get_identifier).to eq user_id

    expect(user.get_attribute("Email")).to eq email
    expect(user.get_attribute("EMAIL")).to be nil
    expect(user.get_attribute("email")).to be nil

    expect(user.get_attribute("Country")).to eq country
    expect(user.get_attribute("COUNTRY")).to be nil
    expect(user.get_attribute("country")).to be nil

    expect(user.get_attribute('custom')).to eq 'test'
    expect(user.get_attribute('non-existing')).to be_nil
  end

  it "to_s" do
    user_id = "id"
    email = "test@test.com"
    country = "country"
    custom = { 'custom' => 'test' }
    user = User.new(user_id, email: email, country: country, custom: custom)

    user_json = JSON.parse(user.to_s)

    expect(user_json['Identifier']).to eq user_id
    expect(user_json['Email']).to eq email
    expect(user_json['Country']).to eq country
    expect(user_json['Custom']).to eq custom
  end
end
