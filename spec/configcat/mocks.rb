require 'configcat/interfaces'
require 'json'

TEST_JSON = '{"testKey": { "v": "testValue", "t": 1, "p": [], "r": [] }}'
TEST_JSON2 = '{"testKey": { "v": "testValue", "t": 1, "p": [], "r": [] }, "testKey2": { "v": "testValue2", "t": 1, "p": [], "r": [] }}'
TEST_OBJECT = JSON.parse('{
  "testBoolKey": {"v": true,"t": 0, "p": [],"r": []},
  "testStringKey": {"v": "testValue","t": 1, "p": [],"r": []},
  "testIntKey": {"v": 1,"t": 2, "p": [],"r": []},
  "testDoubleKey": {"v": 1.1,"t": 3,"p": [],"r": []},
  "key1": {"v": true, "i": "fakeId1","p": [], "r": []},
  "key2": {"v": false, "i": "fakeId2","p": [], "r": []}
}')

include ConfigCat

class FetchResponseMock
  def initialize(json)
    @json = json
  end
  def json()
    return @json
  end
  def is_fetched()
    return true
  end
end

class ConfigFetcherMock < ConfigFetcher
  def initialize()
    @_call_count = 0
    @_configuration = TEST_JSON
  end
  def get_configuration_json()
    @_call_count = @_call_count + 1
    return FetchResponseMock.new(@_configuration)
  end
  def set_configuration_json(value)
    @_configuration = value
  end
  def close()
  end
  def get_call_count()
    return @_call_count
  end
end

class ConfigFetcherWithErrorMock < ConfigFetcher
  def initialize(exception)
    @_exception = exception
  end
  def get_configuration_json()
    raise @_exception
  end
  def close()
  end
end

class ConfigFetcherWaitMock < ConfigFetcher
  def initialize(wait_seconds)
    @_wait_seconds = wait_seconds
  end
  def get_configuration_json()
    sleep(@_wait_seconds)
    return FetchResponseMock.new(TEST_JSON)
  end
  def close()
  end
end

class ConfigFetcherCountMock < ConfigFetcher
  def initialize()
    @_value = 0
  end
  def get_configuration_json()
    @_value += 10
    return FetchResponseMock.new(@_value)
  end
  def close()
  end
end

class ConfigCacheMock < ConfigCache
  def get()
    return TEST_OBJECT
  end
  def set(value)
  end
end

class CallCounter
  def initialize()
    @_call_count = 0
  end
  def callback()
    @_call_count += 1
  end
  def callback_exception()
    @_call_count += 1
    raise Exception, "error"
  end
  def get_call_count()
    return @_call_count
  end
end
