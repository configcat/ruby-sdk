require 'spec_helper'
require 'configcat/configfetcher'
require_relative 'mocks'

RSpec.describe ConfigCat::ConfigFetcher do
  [
    "",
    "null"
  ].each do |body|
    it "fetch_empty_#{body.empty? ? 'empty' : 'null'}" do
      uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
      WebMock.stub_request(:get, uri_template)
        .to_return(status: 200, body: body, headers: {})

      log = ConfigCatLogger.new(Hooks.new)
      fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
      fetch_response = fetcher.get_configuration()

      expect(fetch_response.is_fetched()).to be false
      expect(fetch_response.is_failed()).to be true
      expect(fetch_response.error).to include("Unexpected error occurred while trying to fetch config JSON")
    end
  end

  it "test_simple_fetch_success" do
    test_json = '{"test": "json"}'
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
      .to_return(status: 200, body: test_json, headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.entry.config).to eq JSON.parse(test_json)
    expect(fetch_response.entry.config_json_string).to eq test_json
  end

  it "test_fetch_not_modified_etag" do
    etag = "test"
    test_json = '{"test": "json"}'
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
        .to_return(status: 200, body: test_json, headers: { "ETag" => etag })
    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()
    expect(fetch_response.is_fetched()).to be true
    expect(fetch_response.entry.config).to eq JSON.parse(test_json)
    expect(fetch_response.entry.config_json_string).to eq test_json
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

  it "test_403_failed_fetch_response_logs_1100_invalid_sdk_key" do
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

    logger = ConfigCat.logger
    log_stream = StringIO.new
    ConfigCat.logger = Logger.new(log_stream, level: Logger::ERROR)

    begin
      log = ConfigCatLogger.new(Hooks.new)
      fetcher = ConfigCat::ConfigFetcher.new(TEST_SDK_KEY1, log, "m")
      fetch_response = fetcher.get_configuration()

      expect(fetch_response.is_failed()).to be true
      expect(fetch_response.is_transient_error).to be false

      log_stream.rewind
      error_log = log_stream.read
      expect(error_log).to include("[1100] Your SDK Key seems to be wrong: '**********************/****************000001'.")
      expect(error_log).to include("You can find the valid SDK Key at https://app.configcat.com/sdkkey.")
    ensure
      ConfigCat.logger = logger
    end
  end

  it "retry_on_transient_http_error" do
    test_json = '{"f": {}}'
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    stub = WebMock.stub_request(:get, uri_template)
      .to_return(status: 500, body: "", headers: {})
      .then
      .to_return(status: 200, body: test_json, headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_fetched()).to be true
    expect(WebMock).to have_requested(:get, uri_template).twice
  end

  it "retry_on_timeout" do
    test_json = '{"f": {}}'
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_raise(Timeout::Error.new("timed out"))
      .then
      .to_return(status: 200, body: test_json, headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_fetched()).to be true
    expect(WebMock).to have_requested(:get, uri_template).twice
  end

  it "retry_on_unexpected_error" do
    test_json = '{"f": {}}'
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_raise(SocketError.new("connection reset"))
      .then
      .to_return(status: 200, body: test_json, headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_fetched()).to be true
    expect(WebMock).to have_requested(:get, uri_template).twice
  end

  it "retry_on_transient_http_error_both_fail" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_return(status: 500, body: "", headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be true
    expect(WebMock).to have_requested(:get, uri_template).twice
  end

  it "evict_all_throttled_within_30_seconds" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_return(status: 500, body: "", headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")

    # First failure: connection reset should happen (last_reset is nil)
    fetcher.get_configuration()
    first_reset_time = fetcher.instance_variable_get(:@_last_connection_reset)
    expect(first_reset_time).not_to be_nil

    WebMock.reset!
    WebMock.stub_request(:get, uri_template)
      .to_return(status: 500, body: "", headers: {})

    # Second failure within 30s: reset should NOT update the timestamp
    fetcher.get_configuration()
    second_reset_time = fetcher.instance_variable_get(:@_last_connection_reset)
    expect(second_reset_time).to eq first_reset_time
  end

  it "no_retry_on_403" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_return(status: 403, body: "", headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be false
    expect(WebMock).to have_requested(:get, uri_template).once
  end

  it "no_retry_on_404" do
    uri_template = Addressable::Template.new "https://{base_url}/{base_path}/{api_key}/{base_ext}"
    WebMock.stub_request(:get, uri_template)
      .to_return(status: 404, body: "", headers: {})

    log = ConfigCatLogger.new(Hooks.new)
    fetcher = ConfigCat::ConfigFetcher.new("", log, "m")
    fetch_response = fetcher.get_configuration()

    expect(fetch_response.is_failed()).to be true
    expect(fetch_response.is_transient_error).to be false
    expect(WebMock).to have_requested(:get, uri_template).once
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
