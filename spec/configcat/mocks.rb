require 'configcat/interfaces'
require 'json'

TEST_SDK_KEY = 'configcat-sdk-test-key/0000000000000000000000'
TEST_SDK_KEY1 = 'configcat-sdk-test-key/0000000000000000000001'
TEST_SDK_KEY2 = 'configcat-sdk-test-key/0000000000000000000002'

TEST_JSON = '{
   "p": {
       "u": "https://cdn-global.configcat.com",
       "r": 0
   },
   "f": {
       "testKey": { "v": { "s": "testValue" }, "t": 1 }
   }
}'

TEST_JSON_FORMAT = '{ "f": { "testKey": { "t": %{value_type}, "v": %{value}, "p": [], "r": [] } } }'

TEST_JSON2 = '{
  "p": {
       "u": "https://cdn-global.configcat.com",
       "r": 0
  },
  "f": {
      "testKey": { "v": { "s": "testValue" }, "t": 1 },
      "testKey2": { "v": { "s": "testValue2" }, "t": 1 }
  }
}'

TEST_OBJECT_JSON = '{
  "p": {
    "u": "https://cdn-global.configcat.com",
    "r": 0
  },
  "s": [
    {"n": "id1", "r": [{"a": "Identifier", "c": 2, "l": ["@test1.com"]}]},
    {"n": "id2", "r": [{"a": "Identifier", "c": 2, "l": ["@test2.com"]}]}
  ],
  "f": {
    "testBoolKey": {"v": {"b": true}, "t": 0},
    "testStringKey": {"v": {"s": "testValue"}, "i": "id", "t": 1, "r": [
      {"c": [{"s": {"s": 0, "c": 0}}], "s": {"v": {"s": "fake1"}, "i": "id1"}},
      {"c": [{"s": {"s": 1, "c": 0}}], "s": {"v": {"s": "fake2"}, "i": "id2"}}
    ]},
    "testIntKey": {"v": {"i": 1}, "t": 2},
    "testDoubleKey": {"v": {"d": 1.1}, "t": 3},
    "key1": {"v": {"b": true}, "t": 0, "i": "id3"},
    "key2": {"v": {"s": "fake4"}, "t": 1, "i": "id4",
      "r": [
        {"c": [{"s": {"s": 0, "c": 0}}], "p": [
          {"p": 50, "v": {"s": "fake5"}, "i": "id5"}, {"p": 50, "v": {"s": "fake6"}, "i": "id6"}
        ]}
      ],
      "p": [
        {"p": 50, "v": {"s": "fake7"}, "i": "id7"}, {"p": 50, "v": {"s": "fake8"}, "i": "id8"}
      ]
    }
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
    value_string = "{ \"i\": #{@_value} }"
    config_json_string = TEST_JSON_FORMAT % { value_type: SettingType::INT, value: value_string }
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
