require 'configcat/interfaces'
require 'json'

TEST_JSON = '{' \
            '   "p": {' \
            '       "u": "https://cdn-global.configcat.com",' \
            '       "r": 0' \
            '   },' \
            '   "f": {' \
            '       "testKey": { "v": "testValue", "t": 1, "p": [], "r": [] }' \
            '   }' \
            '}'

TEST_JSON_FORMAT = '{ "f": { "testKey": { "v": %{value}, "p": [], "r": [] } } }'

TEST_JSON2 = '{' \
             '  "p": {' \
             '       "u": "https://cdn-global.configcat.com",' \
             '       "r": 0' \
             '  },' \
             '  "f": {' \
             '      "testKey": { "v": "testValue", "t": 1, "p": [], "r": [] }, ' \
             '      "testKey2": { "v": "testValue2", "t": 1, "p": [], "r": [] }' \
             '  }' \
             '}'

TEST_OBJECT_JSON = '{
  "p": {"u": "https://cdn-global.configcat.com", "r": 0},
  "f": {
    "testBoolKey": {"v": true,"t": 0, "p": [],"r": []},
    "testStringKey": {"v": "testValue", "i": "id", "t": 1, "p": [],"r": [
      {"i":"id1","v":"fake1","a":"Identifier","t":2,"c":"@test1.com"},
      {"i":"id2","v":"fake2","a":"Identifier","t":2,"c":"@test2.com"}
    ]},
    "testIntKey": {"v": 1,"t": 2, "p": [],"r": []},
    "testDoubleKey": {"v": 1.1,"t": 3,"p": [],"r": []},
    "key1": {"v": true, "i": "fakeId1","p": [], "r": []},
    "key2": {"v": false, "i": "fakeId2","p": [], "r": []}
  }
}'

TEST_OBJECT = JSON.parse(TEST_OBJECT_JSON)

include ConfigCat

class FetchResponseMock
  def initialize(json)
    @json = json
  end

  def json
    return @json
  end

  def is_fetched
    return true
  end
end

class ConfigFetcherMock
  def initialize
    @_call_count = 0
    @_fetch_count = 0
    @_configuration = TEST_JSON
    @_etag = "test_etag"
  end

  def get_configuration(etag = "")
    @_call_count += 1
    if etag != @_etag
      @_fetch_count += 1
      return FetchResponse.success(ConfigEntry.new(JSON.parse(@_configuration), @_etag, @_configuration, Utils.get_utc_now_seconds_since_epoch))
    end
    return FetchResponse.not_modified
  end

  def set_configuration_json(value)
    if @_configuration != value
      @_configuration = value
      @_etag += "_etag"
    end
  end

  def close
  end

  def get_call_count
    return @_call_count
  end

  def get_fetch_count
    return @_fetch_count
  end
end

class ConfigFetcherWithErrorMock
  def initialize(error)
    @_error = error
  end

  def get_configuration(*)
    return FetchResponse.failure(@_error, true)
  end

  def close
  end
end

class ConfigFetcherWaitMock
  def initialize(wait_seconds)
    @_wait_seconds = wait_seconds
  end

  def get_configuration(etag = '')
    sleep(@_wait_seconds)
    return FetchResponse.success(ConfigEntry.new(JSON.parse(TEST_JSON), etag, TEST_JSON))
  end

  def close
  end
end

class ConfigFetcherCountMock
  def initialize
    @_value = 0
  end

  def get_configuration(etag = '')
    @_value += 1
    config_json_string = TEST_JSON_FORMAT % { value: @_value }
    config = JSON.parse(config_json_string)
    return FetchResponse.success(ConfigEntry.new(config, etag, config_json_string))
  end

  def close
  end
end

class ConfigCacheMock < ConfigCache
  def get(key)
    [Utils::DISTANT_PAST, 'test-etag', JSON.dump(TEST_OBJECT)].join("\n")
  end

  def set(key, value)
  end
end

class SingleValueConfigCache < ConfigCache
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def get(key)
    @value
  end

  def set(key, value)
    @value = value
  end
end

class HookCallbacks
  attr_accessor :is_ready, :is_ready_call_count, :changed_config, :changed_config_call_count, :evaluation_details,
                :evaluation_details_call_count, :error, :error_call_count, :callback_exception_call_count

  def initialize
    @is_ready = false
    @is_ready_call_count = 0
    @changed_config = nil
    @changed_config_call_count = 0
    @evaluation_details = nil
    @evaluation_details_call_count = 0
    @error = nil
    @error_call_count = 0
    @callback_exception_call_count = 0
  end

  def on_client_ready
    @is_ready = true
    @is_ready_call_count += 1
  end

  def on_config_changed(config)
    @changed_config = config
    @changed_config_call_count += 1
  end

  def on_flag_evaluated(evaluation_details)
    @evaluation_details = evaluation_details
    @evaluation_details_call_count += 1
  end

  def on_error(error)
    @error = error
    @error_call_count += 1
  end

  def callback_exception(*args, **kwargs)
    @callback_exception_call_count += 1
    raise Exception, "error"
  end
end
