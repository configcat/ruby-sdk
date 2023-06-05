require 'spec_helper'

_SDK_KEY = "PKDVCLf-Hq-h-kCzMp-L7Q/PaDVCFk9EpmD6sLpGLltTA"
RSpec.describe 'Integration test: DefaultTests', type: :feature do
  it "test_without_sdk_key" do
    expect {
      ConfigCat.get(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end

  it "test_client_works" do
    client = ConfigCat.get(_SDK_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_get_all_keys" do
    client = ConfigCat.get(_SDK_KEY)
    keys = client.get_all_keys
    expect(keys.size).to eq 5
    expect(keys).to include "keySampleText"
  end

  it "test_force_refresh" do
    client = ConfigCat.get(_SDK_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.force_refresh
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end
end

RSpec.describe 'Integration test: AutoPollTests', type: :feature do
  it "test_without_sdk_key" do
    expect {
      ConfigCat.get(nil, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll))
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end

  it "test_client_works" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_valid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll,
                                                                     base_url: "https://cdn.configcat.com"))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_valid_base_url_trailing_slash" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll,
                                                                     base_url: "https://cdn.configcat.com/"))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_invalid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll,
                                                                     base_url: "https://invalidcdn.configcat.com"))
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.close
  end

  it "test_client_works_invalid_proxy" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll,
                                                                     proxy_address: "0.0.0.0",
                                                                     proxy_port: 0,
                                                                     proxy_user: "test",
                                                                     proxy_pass: "test"))
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.close
  end

  it "test_client_works_request_timeout" do
    uri = ConfigCat::BASE_URL_GLOBAL + "/" + ConfigCat::BASE_PATH + _SDK_KEY + ConfigCat::BASE_EXTENSION
    WebMock.stub_request(:get, uri).to_timeout()

    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll))
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.close
  end

  it "test_force_refresh" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.force_refresh
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_wrong_param" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.auto_poll(
      poll_interval_seconds: 0, max_init_wait_time_seconds: -1)))
    sleep(2)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end
end

RSpec.describe 'Integration test: LazyLoadingTests', type: :feature do
  it "test_without_sdk_key" do
    expect {
      ConfigCat.get(nil, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.lazy_load))
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end

  it "test_client_works" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.lazy_load))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_valid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.lazy_load,
                                                                     base_url: "https://cdn.configcat.com"))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_invalid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.lazy_load,
                                                                     base_url: "https://invalidcdn.configcat.com"))
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.close
  end

  it "test_wrong_param" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.lazy_load(
      cache_refresh_interval_seconds: 0)))
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end
end

RSpec.describe 'Integration test: ManualPollingTests', type: :feature do
  it "test_without_sdk_key" do
    expect {
      ConfigCat.get(nil, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll))
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end

  it "test_client_works" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll))
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.force_refresh
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_valid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                                                     base_url: "https://cdn.configcat.com"))
    client.force_refresh
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.close
  end

  it "test_client_works_invalid_base_url" do
    client = ConfigCat.get(_SDK_KEY, ConfigCat::ConfigCatOptions.new(polling_mode: ConfigCat::PollingMode.manual_poll,
                                                                     base_url: "https://invalidcdn.configcat.com"))
    client.force_refresh
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.close
  end
end
