require 'configcat/interfaces'
require 'configcat/version'
require 'configcat/datagovernance'
require 'configcat/constants'
require 'configcat/configentry'
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

  class Status
    FETCHED = 0,
    NOT_MODIFIED = 1,
    FAILURE = 2
  end

  class FetchResponse
    attr_reader :entry, :error, :is_transient_error

    def initialize(status, entry, error = nil, is_transient_error = false)
      @status = status
      @entry = entry
      @error = error
      @is_transient_error = is_transient_error
    end

    def is_fetched
      @status == Status::FETCHED
    end

    def is_not_modified
      @status == Status::NOT_MODIFIED
    end

    def is_failed
      @status == Status::FAILURE
    end

    def self.success(entry)
      FetchResponse.new(Status::FETCHED, entry)
    end

    def self.not_modified
      FetchResponse.new(Status::NOT_MODIFIED, ConfigEntry::EMPTY)
    end

    def self.failure(error, is_transient_error)
      FetchResponse.new(Status::FAILURE, ConfigEntry::EMPTY, error, is_transient_error)
    end
  end

  class ConfigFetcher
    def initialize(sdk_key, log, mode, base_url:nil, proxy_address:nil, proxy_port:nil, proxy_user:nil, proxy_pass:nil,
                   open_timeout:10, read_timeout:30,
                   data_governance:DataGovernance::GLOBAL)
      @_sdk_key = sdk_key
      @log = log
      @_proxy_address = proxy_address
      @_proxy_port = proxy_port
      @_proxy_user = proxy_user
      @_proxy_pass = proxy_pass
      @_open_timeout = open_timeout
      @_read_timeout = read_timeout
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
    end

    def get_open_timeout()
      return @_open_timeout
    end

    def get_read_timeout()
      return @_read_timeout
    end

    # Returns the FetchResponse object contains configuration entry
    def get_configuration(etag = "", retries = 0)
      fetch_response = _fetch(etag)

      # If there wasn't a config change, we return the response.
      if !fetch_response.is_fetched()
        return fetch_response
      end

      preferences = fetch_response.entry.config.fetch(PREFERENCES, nil)
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
      # the SDK should not redirect the calls, and it just has to return the response.
      if @_base_url_overridden && redirect != RedirectMode::FORCE_REDIRECT
        return fetch_response
      end

      # The next call should use the base_url provided in the config json
      @_base_url = base_url

      # If the redirect property == 0 (redirect not needed), return the response
      if redirect == RedirectMode::NO_REDIRECT
        # Return the response
        return fetch_response
      end

      # Try to download again with the new url

      if redirect == RedirectMode::SHOULD_REDIRECT
        @log.warn("Your data_governance parameter at ConfigCatClient initialization is not in sync with your preferences on the ConfigCat Dashboard: https://app.configcat.com/organization/data-governance. Only Organization Admins can set this preference.")
      end

      # To prevent loops we check if we retried at least 3 times with the new base_url
      if retries >= 2
        @log.error("Redirect loop during config.json fetch. Please contact support@configcat.com.")
        return fetch_response
      end

      # Retry the config download with the new base_url
      return get_configuration(etag, retries + 1)
    end

    def close
      if @_http
        @_http = nil
      end
    end

    private

    def _fetch(etag)
      begin
        ConfigCat.logger.debug "Fetching configuration from ConfigCat"
        uri = URI.parse((((@_base_url + ("/")) + BASE_PATH) + @_sdk_key) + BASE_EXTENSION)
        headers = @_headers
        headers["If-None-Match"] = etag.empty? ? nil : etag
        _create_http()
        request = Net::HTTP::Get.new(uri.request_uri, headers)
        response = @_http.request(request)
        case response
        when Net::HTTPSuccess
          ConfigCat.logger.debug "ConfigCat configuration json fetch response code:#{response.code} Cached:#{response['ETag']}"
          response_etag = response["ETag"]
          if response_etag.nil?
            response_etag = ""
          end
          config = JSON.parse(response.body)
          return FetchResponse.success(ConfigEntry.new(config, response_etag, Time.now.utc))
        when Net::HTTPNotModified
          return FetchResponse.not_modified
        when Net::HTTPNotFound, Net::HTTPForbidden
          error = "Double-check your SDK Key at https://app.configcat.com/sdkkey. Received unexpected response: #{response}"
          @log.error(error)
          return FetchResponse.failure(error, false)
        else
          raise Net::HTTPError.new("", response)
        end
      rescue Net::HTTPError => e
        error = "Unexpected HTTP response was received: #{e}"
        @log.error(error)
        return FetchResponse.failure(error, true)
      rescue Timeout::Error => e
        error = "Request timed out. Timeout values: [connect: #{get_open_timeout()}s, read: #{get_read_timeout()}s]"
        @log.error(error)
        return FetchResponse.failure(error, true)
      rescue Exception => e
        error = "An exception occurred during fetching: #{e}"
        @log.error(error)
        return FetchResponse.failure(error, true)
      end
    end

    def _create_http
      uri = URI.parse(@_base_url)
      use_ssl = true if uri.scheme == 'https'
      if @_http.equal?(nil) || @_http.address != uri.host || @_http.port != uri.port || @_http.use_ssl? != use_ssl
        close()
        @_http = Net::HTTP.new(uri.host, uri.port, @_proxy_address, @_proxy_port, @_proxy_user, @_proxy_pass)
        @_http.use_ssl = use_ssl
        @_http.open_timeout = @_open_timeout
        @_http.read_timeout = @_read_timeout
      end
    end
  end
end
