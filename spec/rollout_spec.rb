require 'spec_helper'
require_relative 'configcat/mocks'

RSpec.describe 'Rollout test', type: :feature do
  SCRIPT_DIR = File.dirname(__FILE__)
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
    file_path = File.join(SCRIPT_DIR, file_path)
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

  [
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", nil, nil, nil, "Cat", false, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", nil, nil, "Cat", false, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "a@example.com", nil, "Dog", true, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "a@configcat.com", nil, "Cat", false, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "a@configcat.com", "", "Frog", true, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "a@configcat.com", "US", "Fish", true, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "b@configcat.com", nil, "Cat", false, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "b@configcat.com", "", "Falcon", false, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/P4e3fAz_1ky2-Zg2e4cbkw", "stringMatchedTargetingRuleAndOrPercentageOption", "12345", "b@configcat.com", "US", "Spider", false, true]
  ].each do |sdk_key, key, user_id, email, percentage_base, expected_return_value, expected_matched_targeting_rule, expected_matched_percentage_option|
    it "test_evaluation_details_matched_evaluation_rule_and_percentage_option (#{sdk_key}, #{key}, #{user_id}, #{email}, #{percentage_base}, #{expected_return_value}, #{expected_matched_targeting_rule}, #{expected_matched_percentage_option})" do
      client = ConfigCat.get(sdk_key, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll))
      client.force_refresh

      user = user_id ? ConfigCat::User.new(user_id, email: email, custom: { "PercentageBase" => percentage_base }) : nil

      evaluation_details = client.get_value_details(key, nil, user)

      expect(evaluation_details.value).to eq(expected_return_value)
      expect(!!evaluation_details.matched_targeting_rule).to eq(expected_matched_targeting_rule)
      expect(!!evaluation_details.matched_percentage_option).to eq(expected_matched_percentage_option)
    end
  end

  it "test user object attribute value conversion text comparison" do
    begin
      # Setup logging
      logger = ConfigCat.logger
      log_stream = StringIO.new
      ConfigCat.logger = Logger.new(log_stream, level: Logger::WARN)

      client = ConfigCatClient.get("configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
      client.force_refresh

      custom_attribute_name = 'Custom1'
      custom_attribute_value = 42
      user = User.new('12345', custom: {custom_attribute_name => custom_attribute_value})

      key = 'boolTextEqualsNumber'
      value = client.get_value(key, nil, user)
      expect(value).to eq(true)

      log_stream.rewind
      log = log_stream.read

      expect(log).to include("[3005] Evaluation of condition (User.#{custom_attribute_name} EQUALS '#{custom_attribute_value}') " \
                             "for setting '#{key}' may not produce the expected result (the User.#{custom_attribute_name} " \
                             "attribute is not a string value, thus it was automatically converted to the string value " \
                             "'#{custom_attribute_value}'). Please make sure that using a non-string value was intended.")
    ensure
      client.close
      ConfigCat.logger = logger
    end
  end

  it "test wrong config json type mismatch" do
    begin
      config = {
        'f' => {
          'test' => {
            't' => 1,  # SettingType.STRING
            'v' => { 'b' => true },  # bool value instead of string (type mismatch)
            'p' => [],
            'r' => []
          }
        }
      }

      # Setup logging
      logger = ConfigCat.logger
      log_stream = StringIO.new
      ConfigCat.logger = Logger.new(log_stream, level: Logger::ERROR)
      log = ConfigCatLogger.new(Hooks.new)
      evaluator = RolloutEvaluator.new(log)

      value, = evaluator.evaluate(key: 'test', user: nil, default_value: false, default_variation_id: 'default_variation_id',
                                  config: config, log_builder: nil)

      expect(value).to be false
      log_stream.rewind
      error_log = log_stream.read
      expect(error_log).to include("[2001] Failed to evaluate setting 'test'. " \
                                   "(Setting value is not of the expected type String)")
    ensure
      ConfigCat.logger = logger
    end
  end

  [
    # SemVer-based comparisons
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", "0.0", "20%"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", "0.9.9", "< 1.0.0"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", "1.0.0", "20%"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", "1.1", "20%"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", 0, "20%"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", 0.9, "20%"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/iV8vH2MBakKxkFZylxHmTg", "lessThanWithPercentage", "12345", "Custom1", 2, "20%"],
    # Number-based comparisons
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", -Float::INFINITY, "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", -1, "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", 2, "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", 2.1, "<=2,1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", 3, "<>4.2"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", 5, ">=5"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", Float::INFINITY, ">5"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", Float::NAN, "<>4.2"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "-Infinity", "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "-1", "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "2", "<2.1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "2.1", "<=2,1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "2,1", "<=2,1"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "3", "<>4.2"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "5", ">=5"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "Infinity", ">5"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "NaN", "<>4.2"],
    ["configcat-sdk-1/PKDVCLf-Hq-h-kCzMp-L7Q/FCWN-k1dV0iBf8QZrDgjdw", "numberWithPercentage", "12345", "Custom1", "NaNa", "80%"],
    # Date time-based comparisons
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-03-31T23:59:59.9990000Z"), false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-04-01T01:59:59.9990000+02:00"), false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-04-01T00:00:00.0010000Z"), true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-04-01T02:00:00.0010000+02:00"), true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-04-30T23:59:59.9990000Z"), true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-05-01T01:59:59.9990000+02:00"), true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-05-01T00:00:00.0010000Z"), false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", DateTime.parse("2023-05-01T02:00:00.0010000+02:00"), false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", -Float::INFINITY, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1680307199.999, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1680307200.001, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1682899199.999, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1682899200.001, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", Float::INFINITY, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", Float::NAN, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1680307199, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1680307201, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1682899199, true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", 1682899201, false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "-Infinity", false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "1680307199.999", false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "1680307200.001", true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "1682899199.999", true],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "1682899200.001", false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "+Infinity", false],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "boolTrueIn202304", "12345", "Custom1", "NaN", false],
    # String array-based comparisons
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "stringArrayContainsAnyOfDogDefaultCat", "12345", "Custom1", ["x", "read"], "Dog"],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "stringArrayContainsAnyOfDogDefaultCat", "12345", "Custom1", ["x", "Read"], "Cat"],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "stringArrayContainsAnyOfDogDefaultCat", "12345", "Custom1", "[\"x\", \"read\"]", "Dog"],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "stringArrayContainsAnyOfDogDefaultCat", "12345", "Custom1", "[\"x\", \"Read\"]", "Cat"],
    ["configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/OfQqcTjfFUGBwMKqtyEOrQ", "stringArrayContainsAnyOfDogDefaultCat", "12345", "Custom1", "x, read", "Cat"]
  ].each do |sdk_key, key, user_id, custom_attribute_name, custom_attribute_value, expected_return_value|
    it "test_user_object_attribute_value_conversion_non_text_comparisons (#{sdk_key}, #{key}, #{user_id}, #{custom_attribute_name}, #{custom_attribute_value}, #{custom_attribute_value.class}, #{expected_return_value})" do
      client = ConfigCat.get(sdk_key, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll))
      client.force_refresh
      user = ConfigCat::User.new(user_id, custom: { custom_attribute_name => custom_attribute_value })
      value = client.get_value(key, nil, user)

      expect(value).to eq(expected_return_value)
      client.close
    end
  end

  [
    ["numberToStringConversion", 0.12345, "1"],
    ["numberToStringConversionInt", 125.0, "4"],
    ["numberToStringConversionPositiveExp", -1.23456789e96, "2"],
    ["numberToStringConversionNegativeExp", -12345.6789E-100, "4"],
    ["numberToStringConversionNaN",  Float::NAN, "3"],
    ["numberToStringConversionPositiveInf", Float::INFINITY, "4"],
    ["numberToStringConversionNegativeInf", -Float::INFINITY, "3"],
    ["dateToStringConversion", DateTime.parse("2023-03-31T23:59:59.9990000Z"), "3"],
    ["dateToStringConversion", 1680307199.999, "3"],  # Assuming this needs conversion to date
    ["dateToStringConversionNaN", Float::NAN, "3"],
    ["dateToStringConversionPositiveInf", Float::INFINITY, "1"],
    ["dateToStringConversionNegativeInf", -Float::INFINITY, "5"],
    ["stringArrayToStringConversion", ["read", "Write", " eXecute "], "4"],
    ["stringArrayToStringConversionEmpty", [], "5"],
    ["stringArrayToStringConversionSpecialChars", ["+<>%\"'\\/\t\r\n"], "3"],
    ["stringArrayToStringConversionUnicode", ["äöüÄÖÜçéèñışğâ¢™✓😀"], "2"],
  ].each do |key, custom_attribute_value, expected_return_value|
    it "test_attribute_conversion_to_canonical_string (#{key}, #{custom_attribute_value}, #{expected_return_value})" do
      config = LocalFileDataSource.new(File.join(SCRIPT_DIR, "data/comparison_attribute_conversion.json"), OverrideBehaviour::LOCAL_ONLY, nil).get_overrides

      log = ConfigCatLogger.new(Hooks.new)
      evaluator = RolloutEvaluator.new(log)
      user = ConfigCat::User.new("12345", custom: { "Custom1" => custom_attribute_value })

      value, = evaluator.evaluate(key: key, user: user, default_value: 'default_value', default_variation_id: 'default_variation_id',
                                  config: config, log_builder: nil)
      expect(value).to eq(expected_return_value)
    end
  end

  [
    ["isoneof", "no trim"],
    ["isnotoneof", "no trim"],
    ["isoneofhashed", "no trim"],
    ["isnotoneofhashed", "no trim"],
    ["equalshashed", "no trim"],
    ["notequalshashed", "no trim"],
    ["arraycontainsanyofhashed", "no trim"],
    ["arraynotcontainsanyofhashed", "no trim"],
    ["equals", "no trim"],
    ["notequals", "no trim"],
    ["startwithanyof", "no trim"],
    ["notstartwithanyof", "no trim"],
    ["endswithanyof", "no trim"],
    ["notendswithanyof", "no trim"],
    ["arraycontainsanyof", "no trim"],
    ["arraynotcontainsanyof", "no trim"],
    ["startwithanyofhashed", "no trim"],
    ["notstartwithanyofhashed", "no trim"],
    ["endswithanyofhashed", "no trim"],
    ["notendswithanyofhashed", "no trim"],
    # semver comparators user values trimmed because of backward compatibility
    ["semverisoneof", "4 trim"],
    ["semverisnotoneof", "5 trim"],
    ["semverless", "6 trim"],
    ["semverlessequals", "7 trim"],
    ["semvergreater", "8 trim"],
    ["semvergreaterequals", "9 trim"],
    # number and date comparators user values trimmed because of backward compatibility
    ["numberequals", "10 trim"],
    ["numbernotequals", "11 trim"],
    ["numberless", "12 trim"],
    ["numberlessequals", "13 trim"],
    ["numbergreater", "14 trim"],
    ["numbergreaterequals", "15 trim"],
    ["datebefore", "18 trim"],
    ["dateafter", "19 trim"],
    # "contains any of" and "not contains any of" is a special case, the not trimmed user attribute checked against not trimmed comparator values.
    ["containsanyof", "no trim"],
    ["notcontainsanyof", "no trim"],
  ].each do |key, expected_return_value|
    it "test_comparison_attribute_trimming (#{key}, #{expected_return_value})" do
      config = LocalFileDataSource.new(File.join(SCRIPT_DIR, "data/comparison_attribute_trimming.json"), OverrideBehaviour::LOCAL_ONLY, nil).get_overrides

      log = ConfigCatLogger.new(Hooks.new)
      evaluator = RolloutEvaluator.new(log)
      user = ConfigCat::User.new(" 12345 ", country: '[" USA "]', custom: {
        'Version' => ' 1.0.0 ',
        'Number' => ' 3 ',
        'Date' => ' 1705253400 '
      })
      value, = evaluator.evaluate(key: key, user: user, default_value: 'default_value', default_variation_id: 'default_variation_id',
                                  config: config, log_builder: nil)
      expect(value).to eq(expected_return_value)
    end
  end

  [
    ["isoneof", "no trim"],
    ["isnotoneof", "no trim"],
    ["isoneofhashed", "no trim"],
    ["isnotoneofhashed", "no trim"],
    ["equalshashed", "no trim"],
    ["notequalshashed", "no trim"],
    ["arraycontainsanyofhashed", "no trim"],
    ["arraynotcontainsanyofhashed", "no trim"],
    ["equals", "no trim"],
    ["notequals", "no trim"],
    ["startwithanyof", "no trim"],
    ["notstartwithanyof", "no trim"],
    ["endswithanyof", "no trim"],
    ["notendswithanyof", "no trim"],
    ["arraycontainsanyof", "no trim"],
    ["arraynotcontainsanyof", "no trim"],
    ["startwithanyofhashed", "no trim"],
    ["notstartwithanyofhashed", "no trim"],
    ["endswithanyofhashed", "no trim"],
    ["notendswithanyofhashed", "no trim"],
    # semver comparators user values trimmed because of backward compatibility
    ["semverisoneof", "4 trim"],
    ["semverisnotoneof", "5 trim"],
    ["semverless", "6 trim"],
    ["semverlessequals", "7 trim"],
    ["semvergreater", "8 trim"],
    ["semvergreaterequals", "9 trim"]
  ].each do |key, expected_return_value|
    it "test_comparison_value_trimming (#{key}, #{expected_return_value})" do
      config = LocalFileDataSource.new(File.join(SCRIPT_DIR, "data/comparison_value_trimming.json"), OverrideBehaviour::LOCAL_ONLY, nil).get_overrides

      log = ConfigCatLogger.new(Hooks.new)
      evaluator = RolloutEvaluator.new(log)
      user = ConfigCat::User.new("12345", country: '["USA"]', custom: {
        'Version' => '1.0.0',
        'Number' => '3',
        'Date' => '1705253400'
      })
      value, = evaluator.evaluate(key: key, user: user, default_value: 'default_value', default_variation_id: 'default_variation_id',
                                  config: config, log_builder: nil)
      expect(value).to eq(expected_return_value)
    end
  end

  [
    ["key1", "'key1' -> 'key1'"],
    ["key2", "'key2' -> 'key3' -> 'key2'"],
    ["key4", "'key4' -> 'key3' -> 'key2' -> 'key3'"]
  ].each do |key, dependency_cycle|
    it "test_prerequisite_flag_circular_dependency (#{key}, #{dependency_cycle})" do
      begin
        config = LocalFileDataSource.new(File.join(SCRIPT_DIR, "data/test_circulardependency_v6.json"), OverrideBehaviour::LOCAL_ONLY, nil).get_overrides

        # Setup logging
        logger = ConfigCat.logger
        log_stream = StringIO.new
        ConfigCat.logger = Logger.new(log_stream, level: Logger::ERROR)

        log = ConfigCatLogger.new(Hooks.new)
        evaluator = RolloutEvaluator.new(log)
        value, = evaluator.evaluate(key: key, user: nil, default_value: 'default_value', default_variation_id: 'default_variation_id',
                                    config: config, log_builder: nil)
        expect(value).to eq('default_value')
        log_stream.rewind
        error_log = log_stream.read
        expect(error_log).to include("Circular dependency detected")
        expect(error_log).to include(dependency_cycle)
      ensure
        ConfigCat.logger = logger
      end
    end
  end

  [
    ["stringDependsOnBool", "mainBoolFlag", true, "Dog"],
    ["stringDependsOnBool", "mainBoolFlag", false, "Cat"],
    ["stringDependsOnBool", "mainBoolFlag", "1", nil],
    ["stringDependsOnBool", "mainBoolFlag", 1, nil],
    ["stringDependsOnBool", "mainBoolFlag", 1.0, nil],
    ["stringDependsOnBool", "mainBoolFlag", [true], nil],
    ["stringDependsOnBool", "mainBoolFlag", nil, nil],
    ["stringDependsOnString", "mainStringFlag", "private", "Dog"],
    ["stringDependsOnString", "mainStringFlag", "Private", "Cat"],
    ["stringDependsOnString", "mainStringFlag", true, nil],
    ["stringDependsOnString", "mainStringFlag", 1, nil],
    ["stringDependsOnString", "mainStringFlag", 1.0, nil],
    ["stringDependsOnString", "mainStringFlag", ["private"], nil],
    ["stringDependsOnString", "mainStringFlag", nil, nil],
    ["stringDependsOnInt", "mainIntFlag", 2, "Dog"],
    ["stringDependsOnInt", "mainIntFlag", 1, "Cat"],
    ["stringDependsOnInt", "mainIntFlag", "2", nil],
    ["stringDependsOnInt", "mainIntFlag", true, nil],
    ["stringDependsOnInt", "mainIntFlag", 2.0, nil],
    ["stringDependsOnInt", "mainIntFlag", [2], nil],
    ["stringDependsOnInt", "mainIntFlag", nil, nil],
    ["stringDependsOnDouble", "mainDoubleFlag", 0.1, "Dog"],
    ["stringDependsOnDouble", "mainDoubleFlag", 0.11, "Cat"],
    ["stringDependsOnDouble", "mainDoubleFlag", "0.1", nil],
    ["stringDependsOnDouble", "mainDoubleFlag", true, nil],
    ["stringDependsOnDouble", "mainDoubleFlag", 1, nil],
    ["stringDependsOnDouble", "mainDoubleFlag", [0.1], nil],
    ["stringDependsOnDouble", "mainDoubleFlag", nil, nil],
  ].each do |key, prerequisite_flag_key, prerequisite_flag_value, expected_value|
    it "test_prerequisite_flag_comparison_value_type_mismatch (#{key}, #{prerequisite_flag_key}, #{prerequisite_flag_value}, #{expected_value})" do
      begin
        # Setup logging
        logger = ConfigCat.logger
        log_stream = StringIO.new
        ConfigCat.logger = Logger.new(log_stream, level: Logger::WARN)

        override_dictionary = { prerequisite_flag_key => prerequisite_flag_value }
        options = ConfigCatOptions.new(
          polling_mode: PollingMode.manual_poll,
          flag_overrides: ConfigCat::LocalDictionaryFlagOverrides.new(
            override_dictionary,
            ConfigCat::OverrideBehaviour::LOCAL_OVER_REMOTE
          )
        )
        client = ConfigCatClient.get("configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/JoGwdqJZQ0K2xDy7LnbyOg", options)
        client.force_refresh

        value = client.get_value(key, nil)
        expect(value).to eq(expected_value)

        if expected_value.nil?
          log_stream.rewind
          error_log = log_stream.read
          prerequisite_flag_value_type = SettingType.to_type(SettingType.from_type(prerequisite_flag_value.class))

          if prerequisite_flag_value.nil? || prerequisite_flag_value_type.nil?
            expect(error_log).to include('Unsupported setting type')
          else
            expect(error_log).to include("Setting value is not of the expected type #{prerequisite_flag_value_type}")
          end
        end
      ensure
        client.close
        ConfigCat.logger = logger
      end
    end
  end

end
