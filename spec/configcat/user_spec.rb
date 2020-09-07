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
    email = "test@test.com"
    country = "country"
    user = User.new("user_id", email: email, country: country)
    expect(user.get_attribute("Email")).to eq email
    expect(user.get_attribute("EMAIL")).to be nil
    expect(user.get_attribute("email")).to be nil
    expect(user.get_attribute("Country")).to eq country
    expect(user.get_attribute("COUNTRY")).to be nil
    expect(user.get_attribute("country")).to be nil
  end
end
