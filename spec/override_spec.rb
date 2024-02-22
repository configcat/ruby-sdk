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
end
