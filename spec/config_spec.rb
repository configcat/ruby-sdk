require 'spec_helper'
require 'configcat/localdictionarydatasource'
require 'configcat/localfiledatasource'
require 'tempfile'
require 'json'
require_relative 'configcat/mocks'


RSpec.describe 'Config test', type: :feature do
  it "test_value_setting_type_is_missing" do
    value_dictionary = {
      't' => 6,  # unsupported setting type
      'v' => {
        'b' => true
      }
    }
    setting_type = value_dictionary[SETTING_TYPE]
    expect { Config.get_value(value_dictionary, setting_type) }.to raise_error("Unsupported setting type")
  end

  it "test_value_setting_type_is_valid_but_return_value_is_missing" do
    value_dictionary = {
      't' => 0,  # boolean
      'v' => {
        's' => true  # the wrong property is set ("b" should be set)
      }
    }
    setting_type = value_dictionary[SETTING_TYPE]
    expect { Config.get_value(value_dictionary, setting_type) }.to raise_error("Setting value is not of the expected type TrueClass")
  end

  it "test_value_setting_type_is_valid_and_the_return_value_is_present_but_it_is_invalid" do
    value_dictionary = {
      't' => 0,  # boolean
      'v' => {
        'b' => 'true'  # the value is a string instead of a boolean
      }
    }
    setting_type = value_dictionary[SETTING_TYPE]
    expect { Config.get_value(value_dictionary, setting_type) }.to raise_error("Setting value is not of the expected type TrueClass")
  end
end
