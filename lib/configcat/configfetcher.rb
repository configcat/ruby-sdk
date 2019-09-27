require 'configcat/interfaces'
require 'configcat/version'
require 'net/http'
require 'uri'
require 'json'

module ConfigCat
  BASE_URL = "https://cdn.configcat.com"
  BASE_PATH = "configuration-files/"
  BASE_EXTENSION = "/config_v2.json"

  class CacheControlConfigFetcher < ConfigFetcher
    def initialize(api_key, mode, base_url=nil)
      @_api_key = api_key
      @_headers = {"User-Agent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "X-ConfigCat-UserAgent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "Content-Type" => "application/json"}
      if !base_url.equal?(nil)
        @_base_url = base_url.chomp("/")
      else
        @_base_url = BASE_URL
      end
      uri = URI.parse(@_base_url)
      @_http = Net::HTTP.new(uri.host, uri.port)
      @_http.use_ssl = true if uri.scheme == 'https'
      @_http.open_timeout = 10 # in seconds
      @_http.read_timeout = 30 # in seconds
    end

    def get_configuration_json()
      # TODO: logger is needed
      # log.debug("Fetching configuration from ConfigCat")
      uri = URI.parse((((@_base_url + ("/")) + BASE_PATH) + @_api_key) + BASE_EXTENSION)
      request = Net::HTTP::Get.new(uri.request_uri, @_headers)
      response = @_http.request(request)
      json = JSON.parse(response.body)
      # log.debug("ConfigCat configuration json fetch response code:[%d] Cached:[%s]", response.status_code, response.from_cache)
      return json
    end

    def close()
      if @_http
        @_http = nil
      end
    end
  end
end
