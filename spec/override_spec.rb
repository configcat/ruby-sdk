require 'spec_helper'
require 'configcat/localdictionarydatasource'
require 'configcat/localfiledatasource'
require 'tempfile'
require 'json'
require_relative 'configcat/mocks'


RSpec.describe 'Override test', type: :feature do
  script_dir = File.dirname(__FILE__)

  def stub_request
    json = '{"f": {"fakeKey": {"v": {"b": false}, "t": 0}, "fakeKey2": {"v": {"s": "test"}, "t": 1}}}'
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: json, headers: {})
  end

  it "test file" do
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalFileFlagOverrides.new(
                                                File.join(script_dir, "data/test.json"),
                                                ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                              )
    )
    client = ConfigCat::ConfigCatClient.get("", options)

    expect(client.get_value("enabledFeature", false)).to eq true
    expect(client.get_value("disabledFeature", true)).to eq false
    expect(client.get_value("intSetting", 0)).to eq 5
    expect(client.get_value("doubleSetting", 0.0)).to eq 3.14
    expect(client.get_value("stringSetting", "")).to eq "test"
    client.close
  end

  it "test simple file" do
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalFileFlagOverrides.new(
                                                File.join(script_dir, "data/test-simple.json"),
                                                ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                              )
    )
    client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)

    expect(client.get_value("enabledFeature", false)).to eq true
    expect(client.get_value("disabledFeature", true)).to eq false
    expect(client.get_value("intSetting", 0)).to eq 5
    expect(client.get_value("doubleSetting", 0.0)).to eq 3.14
    expect(client.get_value("stringSetting", "")).to eq "test"
    client.close
  end

  it "test non existent file" do
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalFileFlagOverrides.new(
                                                File.join(script_dir, "non_existent.json"),
                                                ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                              )
    )
    client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)

    expect(client.get_value("enabledFeature", false)).to eq false
    client.close
  end

  it "test reload file" do
    temp = Tempfile.new("test-simple")
    dictionary = { "flags" => { "enabledFeature" => false } }
    begin
      temp.write(dictionary.to_json)
      temp.flush

      options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                                flag_overrides: ConfigCat::LocalFileFlagOverrides.new(
                                                  temp.path,
                                                  ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                                )
      )
      client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)

      expect(client.get_value("enabledFeature", true)).to eq false

      sleep(0.5)

      # clear the content of the temp file
      temp.seek(0)
      temp.truncate(0)

      # change the temporary file
      dictionary["flags"]["enabledFeature"] = true
      temp.write(dictionary.to_json)
      temp.flush

      expect(client.get_value("enabledFeature", false)).to eq true

      client.close
    ensure
      temp.unlink
    end
  end

  it "test invalid file" do
    temp = Tempfile.new("invalid")
    begin
      temp.write('{"flags": {"enabledFeature": true}')
      temp.close

      options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                                flag_overrides: ConfigCat::LocalFileFlagOverrides.new(
                                                  temp.path,
                                                  ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                                )
      )
      client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)

      expect(client.get_value("enabledFeature", false)).to eq false
      client.close
    ensure
      temp.unlink
    end
  end

  it "test dictionary" do
    dictionary = {
        "enabledFeature" => true,
        "disabledFeature" => false,
        "intSetting" => 5,
        "doubleSetting" => 3.14,
        "stringSetting" => "test"
    }
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalDictionaryFlagOverrides.new(
                                                dictionary,
                                                ConfigCat::OverrideBehaviour::LOCAL_ONLY
                                              )
    )
    client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)

    expect(client.get_value("enabledFeature", false)).to eq true
    expect(client.get_value("disabledFeature", true)).to eq false
    expect(client.get_value("intSetting", 0)).to eq 5
    expect(client.get_value("doubleSetting", 0.0)).to eq 3.14
    expect(client.get_value("stringSetting", "")).to eq "test"
    client.close
  end

  it "test local over remote" do
    stub_request
    dictionary = {
        "fakeKey" => true,
        "nonexisting" => true
    }
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalDictionaryFlagOverrides.new(
                                                dictionary,
                                                ConfigCat::OverrideBehaviour::LOCAL_OVER_REMOTE
                                              )
    )
    client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)
    client.force_refresh

    expect(client.get_value("fakeKey", false)).to eq true
    expect(client.get_value("nonexisting", false)).to eq true

    client.close
  end

  it "test remote over local" do
    stub_request
    dictionary = {
        "fakeKey" => true,
        "nonexisting" => true
    }
    options = ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                              flag_overrides: ConfigCat::LocalDictionaryFlagOverrides.new(
                                                dictionary,
                                                ConfigCat::OverrideBehaviour::REMOTE_OVER_LOCAL
                                              )
    )
    client = ConfigCat::ConfigCatClient.get(TEST_SDK_KEY, options)
    client.force_refresh

    expect(client.get_value("fakeKey", true)).to eq false
    expect(client.get_value("nonexisting", false)).to eq true

    client.close
  end

  [
    ['stringDependsOnString', '1', 'john@sensitivecompany.com', nil, 'Dog'],
    ['stringDependsOnString', '1', 'john@sensitivecompany.com', OverrideBehaviour::REMOTE_OVER_LOCAL, 'Dog'],
    ['stringDependsOnString', '1', 'john@sensitivecompany.com', OverrideBehaviour::LOCAL_OVER_REMOTE, 'Dog'],
    ['stringDependsOnString', '1', 'john@sensitivecompany.com', OverrideBehaviour::LOCAL_ONLY, nil],
    ['stringDependsOnString', '2', 'john@notsensitivecompany.com', nil, 'Cat'],
    ['stringDependsOnString', '2', 'john@notsensitivecompany.com', OverrideBehaviour::REMOTE_OVER_LOCAL, 'Cat'],
    ['stringDependsOnString', '2', 'john@notsensitivecompany.com', OverrideBehaviour::LOCAL_OVER_REMOTE, 'Dog'],
    ['stringDependsOnString', '2', 'john@notsensitivecompany.com', OverrideBehaviour::LOCAL_ONLY, nil],
    ['stringDependsOnInt', '1', 'john@sensitivecompany.com', nil, 'Dog'],
    ['stringDependsOnInt', '1', 'john@sensitivecompany.com', OverrideBehaviour::REMOTE_OVER_LOCAL, 'Dog'],
    ['stringDependsOnInt', '1', 'john@sensitivecompany.com', OverrideBehaviour::LOCAL_OVER_REMOTE, 'Cat'],
    ['stringDependsOnInt', '1', 'john@sensitivecompany.com', OverrideBehaviour::LOCAL_ONLY, nil],
    ['stringDependsOnInt', '2', 'john@notsensitivecompany.com', nil, 'Cat'],
    ['stringDependsOnInt', '2', 'john@notsensitivecompany.com', OverrideBehaviour::REMOTE_OVER_LOCAL, 'Cat'],
    ['stringDependsOnInt', '2', 'john@notsensitivecompany.com', OverrideBehaviour::LOCAL_OVER_REMOTE, 'Dog'],
    ['stringDependsOnInt', '2', 'john@notsensitivecompany.com', OverrideBehaviour::LOCAL_ONLY, nil]
  ].each do |key, user_id, email, override_behaviour, expected_value|
    it "test prerequisite flag override (#{key}, #{user_id}, #{email}, #{override_behaviour}, #{expected_value})" do
      # The flag override alters the definition of the following flags:
      # * 'mainStringFlag': to check the case where a prerequisite flag is overridden (dependent flag: 'stringDependsOnString')
      # * 'stringDependsOnInt': to check the case where a dependent flag is overridden (prerequisite flag: 'mainIntFlag')
      options = ConfigCatOptions.new(
        polling_mode: PollingMode.manual_poll,
        flag_overrides: override_behaviour.nil? ? nil : LocalFileFlagOverrides.new(
          File.join(script_dir, "data/test_override_flagdependency_v6.json"), override_behaviour
        )
      )
      client = ConfigCatClient.get('configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/JoGwdqJZQ0K2xDy7LnbyOg', options)
      client.force_refresh
      value = client.get_value(key, nil, User.new(user_id, email: email))

      expect(value).to eq(expected_value)
      client.close
    end
  end

  [
    ['developerAndBetaUserSegment', '1', 'john@example.com', nil, false],
    ['developerAndBetaUserSegment', '1', 'john@example.com', OverrideBehaviour::REMOTE_OVER_LOCAL, false],
    ['developerAndBetaUserSegment', '1', 'john@example.com', OverrideBehaviour::LOCAL_OVER_REMOTE, true],
    ['developerAndBetaUserSegment', '1', 'john@example.com', OverrideBehaviour::LOCAL_ONLY, true],
    ['notDeveloperAndNotBetaUserSegment', '2', 'kate@example.com', nil, true],
    ['notDeveloperAndNotBetaUserSegment', '2', 'kate@example.com', OverrideBehaviour::REMOTE_OVER_LOCAL, true],
    ['notDeveloperAndNotBetaUserSegment', '2', 'kate@example.com', OverrideBehaviour::LOCAL_OVER_REMOTE, true],
    ['notDeveloperAndNotBetaUserSegment', '2', 'kate@example.com', OverrideBehaviour::LOCAL_ONLY, nil]
  ].each do |key, user_id, email, override_behaviour, expected_value|
    it "test config salt segment override (#{key}, #{user_id}, #{email}, #{override_behaviour}, #{expected_value})" do
      # The flag override uses a different config json salt than the downloaded one and
      # overrides the following segments:
      # * 'Beta Users': User.Email IS ONE OF ['jane@example.com']
      # * 'Developers': User.Email IS ONE OF ['john@example.com']
      options = ConfigCatOptions.new(
        polling_mode: PollingMode.manual_poll,
        flag_overrides: override_behaviour.nil? ? nil : LocalFileFlagOverrides.new(
          File.join(script_dir, "data/test_override_segments_v6.json"), override_behaviour
        )
      )
      client = ConfigCatClient.get('configcat-sdk-1/JcPbCGl_1E-K9M-fJOyKyQ/h99HYXWWNE2bH8eWyLAVMA', options)
      client.force_refresh
      value = client.get_value(key, nil, User.new(user_id, email: email))

      expect(value).to eq(expected_value)
      client.close
    end
  end
end
