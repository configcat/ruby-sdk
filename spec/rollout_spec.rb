require 'spec_helper'

RSpec.describe 'Rollout test', type: :feature do
  VALUE_TEST_TYPE = "value_test"
  VARIATION_TEST_TYPE = "variation_test"

  it "test matrix basic v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d62463-86ec-8fde-f5b5-1c5c426fc830/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/psuH7BGHoUmdONrzzUOY7A", VALUE_TEST_TYPE)
  end

  it "test matrix semantic v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d745f1-f315-7daf-d163-5541d3786e6f/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_semantic.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/BAr3KgLTP0ObzKnBTo5nhA", VALUE_TEST_TYPE)
  end

  it "test matrix semantic 2 v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d77fa1-a796-85f9-df0c-57c448eb9934/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_semantic_2.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/q6jMCFIp-EmuAfnmZhPY7w", VALUE_TEST_TYPE)
  end

  it "test matrix number v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d747f0-5986-c2ef-eef3-ec778e32e10a/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_number.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/uGyK3q9_ckmdxRyI7vjwCw", VALUE_TEST_TYPE)
  end

  it "test matrix sensitive v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d7b724-9285-f4a7-9fcd-00f64f1e83d5/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_sensitive.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/qX3TP2dTj06ZpCCT1h_SPA", VALUE_TEST_TYPE)
  end

  it "test matrix segments old v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d9f207-6883-43e5-868c-cbf677af3fe6/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_segments_old.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/LcYz135LE0qbcacz2mgXnA", VALUE_TEST_TYPE)
  end

  it "test matrix variation id v1" do
    # https://app.configcat.com/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08d774b9-3d05-0027-d5f4-3e76c3dba752/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_variationId.csv", "PKDVCLf-Hq-h-kCzMp-L7Q/nQ5qkhRAUEa6beEyyrVLBA", VARIATION_TEST_TYPE)
  end

  it "test matrix basic" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-1927-4d6b-8fb9-b1472564e2d3/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/AG6C1ngVb0CvM07un6JisQ", VALUE_TEST_TYPE)
  end

  it "test matrix semantic" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-278c-4f83-8d36-db73ad6e2a3a/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_semantic.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", VALUE_TEST_TYPE)
  end

  it "test matrix semantic 2" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-2b2b-451e-8359-abdef494c2a2/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_semantic_2.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/U8nt3zEhDEO5S2ulubCopA", VALUE_TEST_TYPE)
  end

  it "test matrix number" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-0fa3-48d0-8de8-9de55b67fb8b/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_number.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", VALUE_TEST_TYPE)
  end

  it "test matrix sensitive" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-2d62-4e1b-884b-6aa237b34764/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_sensitive.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/-0YmVOUNgEGKkgRF-rU65g", VALUE_TEST_TYPE)
  end

  it "test matrix segments old" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbd6ca-a85f-4ed0-888a-2da18def92b5/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_segments_old.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/y_ZB7o-Xb0Swxth-ZlMSeA", VALUE_TEST_TYPE)
  end

  it "test matrix variation id" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08d5a03c-feb7-af1e-a1fa-40b3329f8bed/08dbc4dc-30c6-4969-8e4c-03f6a8764199/244cf8b0-f604-11e8-b543-f23c917f9d8d
    test_matrix("./data/testmatrix_variationId.csv", "configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/spQnkRTIPEWVivZkWM84lQ", VARIATION_TEST_TYPE)
  end

  it "test matrix comparators v6" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08dbc325-7f69-4fd4-8af4-cf9f24ec8ac9/08dbc325-9a6b-4947-84e2-91529248278a/08dbc325-9ebd-4587-8171-88f76a3004cb
    test_matrix('./data/testmatrix_comparators_v6.csv', 'configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ', VALUE_TEST_TYPE)
  end

  it "test matrix segments" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08dbc325-7f69-4fd4-8af4-cf9f24ec8ac9/08dbc325-9cfb-486f-8906-72a57c693615/08dbc325-9ebd-4587-8171-88f76a3004cb
    test_matrix('data/testmatrix_segments.csv', 'configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/h99HYXWWNE2bH8eWyLAVMA', VALUE_TEST_TYPE)
  end

  it "test matrix prerequisite flag" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08dbc325-7f69-4fd4-8af4-cf9f24ec8ac9/08dbc325-9b74-45cb-86d0-4d61c25af1aa/08dbc325-9ebd-4587-8171-88f76a3004cb
    test_matrix('data/testmatrix_prerequisite_flag.csv', 'configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/JoGwdqJZQ0K2xDy7LnbyOg', VALUE_TEST_TYPE)
  end

  it "test matrix and or" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08dbc325-7f69-4fd4-8af4-cf9f24ec8ac9/08dbc325-9d5e-4988-891c-fd4a45790bd1/08dbc325-9ebd-4587-8171-88f76a3004cb
    test_matrix('data/testmatrix_and_or.csv', 'configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/ByMO9yZNn02kXcm72lnY1A', VALUE_TEST_TYPE)
  end

  it "test_matrix_unicode" do
    # https://app.configcat.com/v2/e7a75611-4256-49a5-9320-ce158755e3ba/08dbc325-7f69-4fd4-8af4-cf9f24ec8ac9/08dbd63c-9774-49d6-8187-5f2aab7bd606/08dbc325-9ebd-4587-8171-88f76a3004cb
    test_matrix('data/testmatrix_unicode.csv', 'configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/Da6w8dBbmUeMUBhh0iEeQQ', VALUE_TEST_TYPE)
  end

  def test_matrix(file_path, sdk_key, type)
    script_dir = File.dirname(__FILE__)
    file_path = File.join(script_dir, file_path)
    content = ""
    open(file_path, "r") { |f|
      content = f.readlines()
    }
    header = content[0].rstrip()
    setting_keys = header.split(";")[4..-1]
    custom_key = header.split(";")[3]
    content.shift()
    client = ConfigCat.get(sdk_key)
    errors = ""
    for line in content
      user_descriptor = line.rstrip().split(";")
      user_object = nil
      if !user_descriptor[0].equal?(nil) && user_descriptor[0] != "##null##"
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
          custom = { custom_key => user_descriptor[3] }
        end
        user_object = ConfigCat::User.new(identifier, email: email, country: country, custom: custom)
      end
      i = 0
      for setting_key in setting_keys
        value = (type == VARIATION_TEST_TYPE) ? client.get_value_details(setting_key, nil, user_object).variation_id : client.get_value(setting_key, nil, user_object)
        if value.to_s != (user_descriptor[i + 4]).to_s
          errors += ((((((("Identifier: " + user_descriptor[0]) + ". SettingKey: ") + setting_key) + ". Expected: ") + ((user_descriptor[i + 4]).to_s)) + ". Result: ") + value.to_s) + ".\n"
        end
        i += 1
      end
    end
    expect(errors).to eq ""
    client.close()
  end

  it "test wrong user object" do
    client = ConfigCat.get("PKDVCLf-Hq-h-kCzMp-L7Q/psuH7BGHoUmdONrzzUOY7A")
    setting_value = client.get_value("stringContainsDogDefaultCat", "Lion", { "Email" => "a@configcat.com" })
    expect(setting_value).to eq "Cat"
    ConfigCat.close_all()
  end
end
