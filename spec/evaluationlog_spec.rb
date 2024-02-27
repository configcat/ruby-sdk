require 'spec_helper'
require_relative 'configcat/mocks'

RSpec.describe 'Evaluation log test', type: :feature do

  it "test_simple_value" do
    expect(test_evaluation_log("./data/evaluation/simple_value.json")).to be true
  end

  it "test_1_targeting_rule" do
    expect(test_evaluation_log("./data/evaluation/1_targeting_rule.json")).to be true
  end

  it "test_2_targeting_rules" do
    expect(test_evaluation_log("./data/evaluation/2_targeting_rules.json")).to be true
  end

  it "test_options_based_on_user_id" do
    expect(test_evaluation_log("./data/evaluation/options_based_on_user_id.json")).to be true
  end

  it "test_options_based_on_custom_attr" do
    expect(test_evaluation_log("./data/evaluation/options_based_on_custom_attr.json")).to be true
  end

  it "test_options_after_targeting_rule" do
    expect(test_evaluation_log("./data/evaluation/options_after_targeting_rule.json")).to be true
  end

  it "test_options_within_targeting_rule" do
    expect(test_evaluation_log("./data/evaluation/options_within_targeting_rule.json")).to be true
  end

  it "test_and_rules" do
    expect(test_evaluation_log("./data/evaluation/and_rules.json")).to be true
  end

  it "test_segment" do
    expect(test_evaluation_log("./data/evaluation/segment.json")).to be true
  end

  it "test_prerequisite_flag" do
    expect(test_evaluation_log("./data/evaluation/prerequisite_flag.json")).to be true
  end

  it "test_semver_validation" do
    expect(test_evaluation_log("./data/evaluation/semver_validation.json")).to be true
  end

  it "test_epoch_date_validation" do
    expect(test_evaluation_log("./data/evaluation/epoch_date_validation.json")).to be true
  end

  it "test_number_validation" do
    expect(test_evaluation_log("./data/evaluation/number_validation.json")).to be true
  end

  it "test_comparators_validation" do
    expect(test_evaluation_log("./data/evaluation/comparators.json")).to be true
  end

  it "test_list_truncation_validation" do
    expect(test_evaluation_log("./data/evaluation/list_truncation.json")).to be true
  end

  def test_evaluation_log(file_path)
    script_dir = File.dirname(__FILE__)
    full_file_path = File.join(script_dir, file_path)
    expect(File.file?(full_file_path)).to be true

    name = File.basename(file_path, '.json')
    file_dir = File.join(File.dirname(full_file_path), name)

    data = JSON.parse(File.read(full_file_path))
    sdk_key = data['sdkKey']
    base_url = data['baseUrl']
    json_override = data['jsonOverride']
    flag_overrides = nil
    if json_override
      flag_overrides = LocalFileFlagOverrides.new(File.join(file_dir, json_override), OverrideBehaviour::LOCAL_ONLY)
      sdk_key ||= TEST_SDK_KEY
    end

    begin
      # Setup logging
      logger = ConfigCat.logger
      log_stream = StringIO.new
      ConfigCat.logger = Logger.new(log_stream, level: Logger::INFO, formatter: proc do |severity, datetime, progname, msg|
        "#{severity} #{msg}\n"
      end)

      client = ConfigCatClient.get(sdk_key, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                 flag_overrides: flag_overrides,
                                                                 base_url: base_url))
      client.force_refresh

      data['tests'].each do |test|
        key = test['key']
        default_value = test['defaultValue']
        return_value = test['returnValue']
        user_data = test['user']
        expected_log_file = test['expectedLog']
        test_name = expected_log_file.sub('.json', '')

        expected_log_file_path = File.join(file_dir, expected_log_file)
        user_object = nil
        if user_data
          identifier = user_data['Identifier']
          email = user_data['Email']
          country = user_data['Country']
          custom = user_data.reject { |k, _| ['Identifier', 'Email', 'Country'].include?(k) }
          custom = nil if custom.empty?
          user_object = User.new(identifier, email: email, country: country, custom: custom)
        end

        # Clear log
        log_stream.reopen("")

        value = client.get_value(key, default_value, user_object)
        log_stream.rewind
        log = log_stream.read

        expect(File.file?(expected_log_file_path)).to be true
        expected_log = File.read(expected_log_file_path)

        # Compare logs and values
        expect(expected_log.strip).to eq(log.strip), "Log mismatch for test: #{test_name}"
        expect(return_value).to eq(value), "Return value mismatch for test: #{test_name}"
      end

    return true
    ensure
      client.close
      ConfigCat.logger = logger
    end
  end
end
