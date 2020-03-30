require 'configcat/interfaces'
require 'configcat/version'
require 'net/http'
require 'uri'
require 'json'

module ConfigCat
  BASE_URL = "https://cdn.configcat.com"
  BASE_PATH = "configuration-files/"
  BASE_EXTENSION = "/config_v4.json"

  class FetchResponse
    def initialize(response)
      @_response = response
    end

    # Returns the json-encoded content of a response, if any
    def json()
      return JSON.parse(@_response.body)
    end

    # Gets whether a new configuration value was fetched or not
    def is_fetched()
      code = @_response.code.to_i
      return 200 <= code && code < 300
    end

    # Gets whether the fetch resulted a '304 Not Modified' or not
    def is_not_modified()
      return @_response.code == "304"
    end
  end

  class CacheControlConfigFetcher < ConfigFetcher
    def initialize(api_key, mode, base_url=nil, proxy_address=nil, proxy_port=nil, proxy_user=nil, proxy_pass=nil)
      @_api_key = api_key
      @_etag = ""
      @_headers = {"User-Agent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "X-ConfigCat-UserAgent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "Content-Type" => "application/json"}
      if !base_url.equal?(nil)
        @_base_url = base_url.chomp("/")
      else
        @_base_url = BASE_URL
      end
      uri = URI.parse(@_base_url)
      @_http = Net::HTTP.new(uri.host, uri.port, proxy_address, proxy_port, proxy_user, proxy_pass)
      @_http.use_ssl = true if uri.scheme == 'https'
      @_http.open_timeout = 10 # in seconds
      @_http.read_timeout = 30 # in seconds
    end

    # Returns the FetchResponse object contains configuration json Dictionary
    def get_configuration_json()
      ConfigCat.logger.debug "Fetching configuration from ConfigCat"
      uri = URI.parse((((@_base_url + ("/")) + BASE_PATH) + @_api_key) + BASE_EXTENSION)
      headers = @_headers
      headers["If-None-Match"] = @_etag unless @_etag.empty?
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      response = @_http.request(request)
      etag = response["ETag"]
      @_etag = etag unless etag.nil? || etag.empty?
      ConfigCat.logger.debug "ConfigCat configuration json fetch response code:#{response.code} Cached:#{response['ETag']}"
      return FetchResponse.new(response)
    end

    def close()
      if @_http
        @_http = nil
      end
    end
  end
end
