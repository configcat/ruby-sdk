require 'spec_helper'

_API_KEY = "PKDVCLf-Hq-h-kCzMp-L7Q/PaDVCFk9EpmD6sLpGLltTA"
RSpec.describe 'Integration test: DefaultTests', type: :feature do
  it "test_without_api_key" do
    expect {
      ConfigCat.create_client(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end
  it "test_client_works" do
    client = ConfigCat.create_client(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_get_all_keys" do
    client = ConfigCat.create_client(_API_KEY)
    keys = client.get_all_keys()
    expect(keys.size).to eq 5
    expect(keys).to include "keySampleText"
  end
  it "test_force_refresh" do
    client = ConfigCat.create_client(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.force_refresh()
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
end

RSpec.describe 'Integration test: AutoPollTests', type: :feature do
  it "test_without_api_key" do
    expect {
      ConfigCat::create_client_with_auto_poll(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end
  it "test_client_works" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_valid_base_url" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY, base_url: "https://cdn.configcat.com")
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_valid_base_url_trailing_slash" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY, base_url: "https://cdn.configcat.com/")
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_invalid_base_url" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY, base_url: "https://invalidcdn.configcat.com")
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.stop()
  end
  it "test_client_works_invalid_proxy" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY,
                                                     proxy_address: "0.0.0.0",
                                                     proxy_port: 0,
                                                     proxy_user: "test",
                                                     proxy_pass: "test")
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.stop()
  end
  it "test_force_refresh" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.force_refresh()
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_wrong_param" do
    client = ConfigCat::create_client_with_auto_poll(_API_KEY, poll_interval_seconds: 0, max_init_wait_time_seconds: -1)
    sleep(2)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
end

RSpec.describe 'Integration test: LazyLoadingTests', type: :feature do
  it "test_without_api_key" do
    expect {
      ConfigCat::create_client_with_lazy_load(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end
  it "test_client_works" do
    client = ConfigCat::create_client_with_lazy_load(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_valid_base_url" do
    client = ConfigCat::create_client_with_lazy_load(_API_KEY, base_url: "https://cdn.configcat.com")
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_invalid_base_url" do
    client = ConfigCat::create_client_with_lazy_load(_API_KEY, base_url: "https://invalidcdn.configcat.com")
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.stop()
  end
  it "test_wrong_param" do
    client = ConfigCat::create_client_with_lazy_load(_API_KEY, cache_time_to_live_seconds: 0)
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
end

RSpec.describe 'Integration test: ManualPollingTests', type: :feature do
  it "test_without_api_key" do
    expect {
      ConfigCat::create_client_with_manual_poll(nil)
    }.to raise_error(ConfigCat::ConfigCatClientException)
  end
  it "test_client_works" do
    client = ConfigCat::create_client_with_manual_poll(_API_KEY)
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.force_refresh()
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_valid_base_url" do
    client = ConfigCat::create_client_with_manual_poll(_API_KEY, base_url: "https://cdn.configcat.com")
    client.force_refresh()
    expect(client.get_value("keySampleText", "default value")).to eq "This text came from ConfigCat"
    client.stop()
  end
  it "test_client_works_invalid_base_url" do
    client = ConfigCat::create_client_with_manual_poll(_API_KEY, base_url: "https://invalidcdn.configcat.com")
    client.force_refresh()
    expect(client.get_value("keySampleText", "default value")).to eq "default value"
    client.stop()
  end
end
