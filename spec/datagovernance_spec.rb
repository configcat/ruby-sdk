require 'spec_helper'
require 'configcat/configfetcher'


RSpec.describe 'Data governance tests', type: :feature do
  BASE_URL_FORCED = "https://forced.configcat.com"
  URI_GLOBAL = ConfigCat::BASE_URL_GLOBAL + "/" + ConfigCat::BASE_PATH + ConfigCat::BASE_EXTENSION
  URI_EU_ONLY = ConfigCat::BASE_URL_EU_ONLY + "/" + ConfigCat::BASE_PATH + ConfigCat::BASE_EXTENSION
  URI_CUSTOM = "https://custom.configcat.com/" + ConfigCat::BASE_PATH + ConfigCat::BASE_EXTENSION
  URI_FORCED = BASE_URL_FORCED + "/" + ConfigCat::BASE_PATH + ConfigCat::BASE_EXTENSION
  TEST_JSON = '{"test": "json"}'

  def stub_request(request_uri, response_uri, redirect)
    json = '{ "p": { "u": "%s", "r": %d }, "f": %s }' % [response_uri, redirect, TEST_JSON]
    WebMock.stub_request(:get, request_uri)
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

  it "test_sdk_global_organization_global" do
    # In this case
    # the first invocation should call https://cdn-global.configcat.com
    # and the second should call https://cdn-global.configcat.com
    # without force redirects

    global_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_GLOBAL, 0)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(1)
    expect(eu_only_stub).to have_been_requested.times(0)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(2)
    expect(eu_only_stub).to have_been_requested.times(0)
  end

  it "test_sdk_eu_organization_global" do
    # In this case
    # the first invocation should call https://cdn-eu.configcat.com
    # and the second should call https://cdn-global.configcat.com
    # without force redirects

    global_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_GLOBAL, 0)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::EU_ONLY)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(2)
  end

  it "test_sdk_global_organization_eu_only" do
    # In this case
    # the first invocation should call https://cdn-global.configcat.com
    # with an immediate redirect to https://cdn-eu.configcat.com
    # and the second should call https://cdn-eu.configcat.com

    global_to_eu_only_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_EU_ONLY, 1)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)
    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(1)
    expect(eu_only_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(1)
    expect(eu_only_stub).to have_been_requested.times(2)
  end

  it "test_sdk_eu_organization_eu_only" do
    # In this case
    # the first invocation should call https://cdn-eu.configcat.com
    # and the second should call https://cdn-eu.configcat.com
    # without redirects

    global_to_eu_only_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_EU_ONLY, 1)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::EU_ONLY)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(2)
  end

  it "test_sdk_global_custom_base_url" do
    # In this case
    # the first invocation should call https://custom.configcat.com
    # and the second should call https://custom.configcat.com
    # without force redirects

    global_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_GLOBAL, 0)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)
    custom_stub = stub_request(URI_CUSTOM, ConfigCat::BASE_URL_GLOBAL, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       "https://custom.configcat.com", nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(0)
    expect(custom_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(0)
    expect(custom_stub).to have_been_requested.times(2)
  end

  it "test_sdk_eu_custom_base_url" do
    # In this case
    # the first invocation should call https://custom.configcat.com
    # and the second should call https://custom.configcat.com
    # without force redirects

    global_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_GLOBAL, 0)
    eu_only_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_EU_ONLY, 0)
    custom_stub = stub_request(URI_CUSTOM, ConfigCat::BASE_URL_GLOBAL, 0)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       "https://custom.configcat.com", nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::EU_ONLY)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(0)
    expect(custom_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_stub).to have_been_requested.times(0)
    expect(eu_only_stub).to have_been_requested.times(0)
    expect(custom_stub).to have_been_requested.times(2)
  end

  it "test_sdk_global_forced" do
    # In this case
    # the first invocation should call https://cdn-global.configcat.com
    # with an immediate redirect to https://forced.configcat.com
    # and the second should call https://forced.configcat.com

    global_to_forced_stub = stub_request(URI_GLOBAL, BASE_URL_FORCED, 2)
    eu_only_to_forced_stub = stub_request(URI_EU_ONLY, BASE_URL_FORCED, 2)
    forced_to_forced_stub = stub_request(URI_FORCED, BASE_URL_FORCED, 2)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(1)
    expect(forced_to_forced_stub).to have_been_requested.times(1)
    expect(eu_only_to_forced_stub).to have_been_requested.times(0)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(1)
    expect(forced_to_forced_stub).to have_been_requested.times(2)
    expect(eu_only_to_forced_stub).to have_been_requested.times(0)
  end

  it "test_sdk_eu_forced" do
    # In this case
    # the first invocation should call https://cdn-eu.configcat.com
    # with an immediate redirect to https://forced.configcat.com
    # and the second should call https://forced.configcat.com

    global_to_forced_stub = stub_request(URI_GLOBAL, BASE_URL_FORCED, 2)
    eu_only_to_forced_stub = stub_request(URI_EU_ONLY, BASE_URL_FORCED, 2)
    forced_to_forced_stub = stub_request(URI_FORCED, BASE_URL_FORCED, 2)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::EU_ONLY)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(0)
    expect(forced_to_forced_stub).to have_been_requested.times(1)
    expect(eu_only_to_forced_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(0)
    expect(forced_to_forced_stub).to have_been_requested.times(2)
    expect(eu_only_to_forced_stub).to have_been_requested.times(1)
  end

  it "test_sdk_base_url_forced" do
    # In this case
    # the first invocation should call https://cdn-eu.configcat.com
    # with an immediate redirect to https://forced.configcat.com
    # and the second should call https://forced.configcat.com

    global_to_forced_stub = stub_request(URI_GLOBAL, BASE_URL_FORCED, 2)
    eu_only_to_forced_stub = stub_request(URI_EU_ONLY, BASE_URL_FORCED, 2)
    forced_to_forced_stub = stub_request(URI_FORCED, BASE_URL_FORCED, 2)
    custom_to_forced_stub = stub_request(URI_CUSTOM, BASE_URL_FORCED, 2)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       "https://custom.configcat.com", nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(0)
    expect(eu_only_to_forced_stub).to have_been_requested.times(0)
    expect(custom_to_forced_stub).to have_been_requested.times(1)
    expect(forced_to_forced_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_forced_stub).to have_been_requested.times(0)
    expect(eu_only_to_forced_stub).to have_been_requested.times(0)
    expect(custom_to_forced_stub).to have_been_requested.times(1)
    expect(forced_to_forced_stub).to have_been_requested.times(2)
  end

  it "test_sdk_redirect_loop" do
    # In this case
    # the first invocation should call https://cdn-global.configcat.com
    # with an immediate redirect to https://cdn-eu.configcat.com
    # with an immediate redirect to https://cdn-global.configcat.com
    # the second invocation should call https://cdn-eu.configcat.com
    # with an immediate redirect to https://cdn-global.configcat.com
    # with an immediate redirect to https://cdn-eu.configcat.com

    global_to_eu_only_stub = stub_request(URI_GLOBAL, ConfigCat::BASE_URL_EU_ONLY, 1)
    eu_only_to_global_stub = stub_request(URI_EU_ONLY, ConfigCat::BASE_URL_GLOBAL, 1)

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m",
                                                       nil, nil, nil, nil, nil,
                                                       ConfigCat::DataGovernance::GLOBAL)

    # First fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(2)
    expect(eu_only_to_global_stub).to have_been_requested.times(1)

    # Second fetch
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json().fetch("f")).to eq JSON.parse(TEST_JSON)
    expect(global_to_eu_only_stub).to have_been_requested.times(3)
    expect(eu_only_to_global_stub).to have_been_requested.times(3)
  end
end
