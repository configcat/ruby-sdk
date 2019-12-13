require 'spec_helper'

RSpec.describe 'Rollout test', type: :feature do
  it "test matrix" do
    test_matrix("./testmatrix.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/psuH7BGHoUmdONrzzUOY7A")
  end

  it "test matrix semantic" do
    test_matrix("./testmatrix_semantic.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/BAr3KgLTP0ObzKnBTo5nhA")
  end

  it "test matrix semantic 2" do
    test_matrix("./testmatrix_semantic_2.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/q6jMCFIp-EmuAfnmZhPY7w")
  end

  it "test matrix number" do
    test_matrix("./testmatrix_number.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/uGyK3q9_ckmdxRyI7vjwCw")
  end

  def test_matrix(file_path, api_key)
    script_dir = File.dirname(__FILE__)
    file_path = File.join(script_dir, file_path)
    content = ""
    open(file_path, "r") {|f|
      content = f.readlines()
    }
    header = content[0].rstrip()
    setting_keys = header.split(";")[4..-1]
    custom_key = header.split(";")[3]
    content.shift()
    client = ConfigCat.create_client(api_key)
    errors = ""
    for line in content
      user_descriptor = line.rstrip().split(";")
      user_object = nil
      if !user_descriptor[0].equal?(nil) && user_descriptor[0] != "" && user_descriptor[0] != "##null##"
        email = nil
        country = nil
        custom = nil
        identifier = user_descriptor[0]
        if !user_descriptor[1].equal?(nil) && user_descriptor[1] != "" && user_descriptor[1] != "##null##"
          email = user_descriptor[1]
        end
        if !user_descriptor[2].equal?(nil) && user_descriptor[2] != "" && user_descriptor[2] != "##null##"
          country = user_descriptor[2]
        end
        if !user_descriptor[3].equal?(nil) && user_descriptor[3] != "" && user_descriptor[3] != "##null##"
          custom = {custom_key => user_descriptor[3]}
        end
        user_object = ConfigCat::User.new(identifier, email: email, country: country, custom: custom)
      end
      i = 0
      for setting_key in setting_keys
        value = client.get_value(setting_key, nil, user_object)
        if value.to_s != (user_descriptor[i + 4]).to_s
          errors += ((((((("Identifier: " + user_descriptor[0]) + ". SettingKey: ") + setting_key) + ". Expected: ") + ((user_descriptor[i + 4]).to_s)) + ". Result: ") + value.to_s) + ".\n"
        end
        i += 1
      end
    end
    expect(errors).to eq ""
    client.stop()
  end

  it "test wrong user object" do
    client = ConfigCat.create_client("PKDVCLf-Hq-h-kCzMp-L7Q/psuH7BGHoUmdONrzzUOY7A")
    setting_value = client.get_value("stringContainsDogDefaultCat", "Lion", {"Email" => "a@configcat.com"})
    expect(setting_value).to eq "Cat"
    client.stop()
  end
end
