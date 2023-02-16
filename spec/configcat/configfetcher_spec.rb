require 'spec_helper'
require 'configcat/configfetcher'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigFetcher do
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

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.entry.config).to eq JSON.parse(TEST_JSON)
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
        .to_return(status: 200, body: TEST_JSON, headers: { "ETag" => etag })
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.entry.config).to eq JSON.parse(TEST_JSON)
    expect(fetch_response.entry.etag).to eq etag

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
        .to_return(status: 304, body: "", headers: { "ETag" => etag })
    fetch_response = fetcher.get_configuration(etag)
    expect(fetch_response.is_fetched()).to be false
    expect(fetch_response.is_not_modified()).to be true

    WebMock.reset!
  end

  it "test_http_error" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template).to_raise(Net::HTTPError.new("error", nil))
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be true
    expect(fetch_response.entry.empty?).to be true
  end

  it "test_exception" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template).to_raise(Exception.new("error"))
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be true
    expect(fetch_response.entry.empty?).to be true
  end

  it "test_404_failed_fetch_response" do
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
           .to_return(status: 404, body: "", headers: {})
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be false
    expect(fetch_response.is_fetched()).to be false
    expect(fetch_response.entry.empty?).to be true
  end

  it "test_403_failed_fetch_response" do
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
           .to_return(status: 403, body: "", headers: {})
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be false
    expect(fetch_response.is_fetched()).to be false
    expect(fetch_response.entry.empty?).to be true
  end

  it "test_server_side_etag" do
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("PKDVCLf-Hq-h-kCzMp-L7Q/HhOWfwVtZ0mb30i9wi17GQ",
                                           log,
                                           "m",
                                           base_url: "https://cdn-eu.configcat.com")
    fetch_response = fetcher.get_configuration()
    etag = fetch_response.entry.etag
    expect(etag).not_to be nil
    expect(etag.empty?).to be false
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.is_not_modified()).to be false

    fetch_response = fetcher.get_configuration(etag)
    expect(fetch_response.is_fetched()).to be false
    expect(fetch_response.is_not_modified()).to be true

    fetch_response = fetcher.get_configuration('')
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.is_not_modified()).to be false
  end
end
