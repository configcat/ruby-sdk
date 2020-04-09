require 'spec_helper'
require 'configcat/configfetcher'
require_relative 'mocks'

RSpec.describe ConfigCat::CacheControlConfigFetcher do
  it "test_simple_fetch_success" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .with(
        body: "",
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
        }
      )
      .to_return(status: 200, body: TEST_JSON, headers: {})

    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m")
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json()).to eq JSON.parse(TEST_JSON)
  end

  it "test_fetch_not_modified_etag" do
    etag = "test"
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
        .with(
            body: "",
            headers: {
                'Accept' => '*/*',
                'Content-Type' => 'application/json',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
            }
        )
        .to_return(status: 200, body: TEST_JSON, headers: {"ETag" => etag})
    fetcher = ConfigCat::CacheControlConfigFetcher.new("", "m")
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.json()).to eq JSON.parse(TEST_JSON)

    WebMock.stub_request(:get, uri_template)
        .with(
            body: "",
            headers: {
                'Accept' => '*/*',
                'Content-Type' => 'application/json',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'If-None-Match' => etag
            }
        )
        .to_return(status: 304, body: "", headers: {})
    fetch_response = fetcher.get_configuration_json()
    expect(fetch_response.is_fetched()).to be false
    expect(fetch_response.is_not_modified()).to be true

    WebMock.reset!
  end
end
