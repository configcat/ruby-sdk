require 'spec_helper'
require 'configcat/localdictionarydatasource'


RSpec.describe 'Local test', type: :feature do

  def stub_request()
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    json = '{"f": {"fakeKey": {"v": false} } }'
    WebMock.stub_request(:get, uri_template)
        .with(
            body: "",
            headers: {
                'Accept' => '*/*',
                'Content-Type' => 'application/json',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
            }
        )
        .to_return(status: 200, body: json, headers: {})
  end

  it "test dictionary" do
    dictionary = {
        "enabledFeature" => true,
        "disabledFeature" => false,
        "intSetting" => 5,
        "doubleSetting" => 3.14,
        "stringSetting" => "test"
    }
    client = ConfigCat::ConfigCatClient.new("test",
                                 poll_interval_seconds: 0,
                                 max_init_wait_time_seconds: 0,
                                 flag_overrides: ConfigCat::LocalDictionaryDataSource.new(dictionary, ConfigCat::OverrideBehaviour::LOCAL_ONLY))
    expect(client.get_value("enabledFeature", false)).to eq true
    expect(client.get_value("disabledFeature", true)).to eq false
    expect(client.get_value("intSetting", 0)).to eq 5
    expect(client.get_value("doubleSetting", 0.0)).to eq 3.14
    expect(client.get_value("stringSetting", "")).to eq "test"
    client.stop()
  end

  it "test local over remote" do
    stub_request()
    dictionary = {
        "fakeKey" => true,
        "nonexisting" => true
    }
    client = ConfigCat::ConfigCatClient.new("test",
                                            poll_interval_seconds: 0,
                                            max_init_wait_time_seconds: 0,
                                            flag_overrides: ConfigCat::LocalDictionaryDataSource.new(dictionary, ConfigCat::OverrideBehaviour::LOCAL_OVER_REMOTE))
    expect(client.get_value("fakeKey", false)).to eq true
    expect(client.get_value("nonexisting", false)).to eq true
    client.force_refresh()
    client.stop()
  end

  it "test remote over local" do
    stub_request()
    dictionary = {
        "fakeKey" => true,
        "nonexisting" => true
    }
    client = ConfigCat::ConfigCatClient.new("test",
                                            poll_interval_seconds: 0,
                                            max_init_wait_time_seconds: 0,
                                            flag_overrides: ConfigCat::LocalDictionaryDataSource.new(dictionary, ConfigCat::OverrideBehaviour::REMOTE_OVER_LOCAL))
    expect(client.get_value("fakeKey", true)).to eq false
    expect(client.get_value("nonexisting", false)).to eq true
    client.force_refresh()
    client.stop()
  end
end
