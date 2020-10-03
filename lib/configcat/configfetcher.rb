require 'configcat/interfaces'
require 'configcat/version'
require 'configcat/datagovernance'
require 'configcat/constants'
require 'net/http'
require 'uri'
require 'json'

module ConfigCat
  BASE_URL_GLOBAL = "https://cdn-global.configcat.com"
  BASE_URL_EU_ONLY = "https://cdn-eu.configcat.com"
  BASE_PATH = "configuration-files/"
  BASE_EXTENSION = "/" + CONFIG_FILE_NAME + ".json"

  class RedirectMode
    NO_REDIRECT = 0
    SHOULD_REDIRECT = 1
    FORCE_REDIRECT = 2
  end

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
    def initialize(sdk_key, mode, base_url=nil, proxy_address=nil, proxy_port=nil, proxy_user=nil, proxy_pass=nil,
                   data_governance=DataGovernance::GLOBAL)
      @_sdk_key = sdk_key
      @_proxy_address = proxy_address
      @_proxy_port = proxy_port
      @_proxy_user = proxy_user
      @_proxy_pass = proxy_pass
      @_etag = ""
      @_headers = {"User-Agent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "X-ConfigCat-UserAgent" => ((("ConfigCat-Ruby/") + mode) + ("-")) + VERSION, "Content-Type" => "application/json"}
      if !base_url.equal?(nil)
        @_base_url_overridden = true
        @_base_url = base_url.chomp("/")
      else
        @_base_url_overridden = false
        if data_governance == DataGovernance::EU_ONLY
          @_base_url = BASE_URL_EU_ONLY
        else
          @_base_url = BASE_URL_GLOBAL
        end
      end
      _create_http()
    end

    # Returns the FetchResponse object contains configuration json Dictionary
    def get_configuration_json(retries=0)
      ConfigCat.logger.debug "Fetching configuration from ConfigCat"
      uri = URI.parse((((@_base_url + ("/")) + BASE_PATH) + @_sdk_key) + BASE_EXTENSION)
      headers = @_headers
      headers["If-None-Match"] = @_etag unless @_etag.empty?
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      response = @_http.request(request)
      etag = response["ETag"]
      @_etag = etag unless etag.nil? || etag.empty?
      ConfigCat.logger.debug "ConfigCat configuration json fetch response code:#{response.code} Cached:#{response['ETag']}"
      fetch_response = FetchResponse.new(response)

      # If there wasn't a config change, we return the response.
      if !fetch_response.is_fetched()
        return fetch_response
      end

      preferences = fetch_response.json().fetch(PREFERENCES, nil)
      if preferences === nil
        return fetch_response
      end

      base_url = preferences.fetch(BASE_URL, nil)

      # If the base_url is the same as the last called one, just return the response.
      if base_url.equal?(nil) || @_base_url == base_url
        return fetch_response
      end

      redirect = preferences.fetch(REDIRECT, nil)
      # If the base_url is overridden, and the redirect parameter is not 2 (force),
      # the SDK should not redirect the calls and it just have to return the response.
      if @_base_url_overridden && redirect != RedirectMode::FORCE_REDIRECT
        return fetch_response
      end

      # The next call should use the base_url provided in the config json
      @_base_url = base_url
      _create_http()

      # If the redirect property == 0 (redirect not needed), return the response
      if redirect == RedirectMode::NO_REDIRECT
        # Return the response
        return fetch_response
      end

      # Try to download again with the new url

      if redirect == RedirectMode::SHOULD_REDIRECT
        ConfigCat.logger.warn("Your data_governance parameter at ConfigCatClient initialization is not in sync with your preferences on the ConfigCat Dashboard: https://app.configcat.com/organization/data-governance. Only Organization Admins can set this preference.")
      end

      # To prevent loops we check if we retried at least 3 times with the new base_url
      if retries >= 2
        ConfigCat.logger.error("Redirect loop during config.json fetch. Please contact support@configcat.com.")
        return fetch_response
      end

      # Retry the config download with the new base_url
      return get_configuration_json(retries + 1)
    end

    def close()
      if @_http
        @_http = nil
      end
    end

    def _create_http()
      close()
      uri = URI.parse(@_base_url)
      @_http = Net::HTTP.new(uri.host, uri.port, @_proxy_address, @_proxy_port, @_proxy_user, @_proxy_pass)
      @_http.use_ssl = true if uri.scheme == 'https'
      @_http.open_timeout = 10 # in seconds
      @_http.read_timeout = 30 # in seconds
    end
  end
end
