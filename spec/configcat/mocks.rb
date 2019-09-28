require 'configcat/interfaces'
require 'json'

TEST_JSON = "{\"testKey\": { \"Value\": \"testValue\", \"SettingType\": 1, \"PercentageRolloutItems\": [], \"TargetedRolloutRules\": [] }}"
TEST_JSON2 = "{\"testKey\": { \"Value\": \"testValue\", \"SettingType\": 1, \"PercentageRolloutItems\": [], \"TargetedRolloutRules\": [] }, \"testKey2\": { \"Value\": \"testValue2\", \"SettingType\": 1, \"PercentageRolloutItems\": [], \"TargetedRolloutRules\": [] }}"
TEST_OBJECT = JSON.parse("{\"testBoolKey\": {\"Value\": true,\"SettingType\": 0, \"PercentageRolloutItems\": [],\"TargetedRolloutRules\": []},\"testStringKey\": {\"Value\": \"testValue\",\"SettingType\": 1, \"PercentageRolloutItems\": [],\"TargetedRolloutRules\": []},\"testIntKey\": {\"Value\": 1,\"SettingType\": 2, \"PercentageRolloutItems\": [],\"TargetedRolloutRules\": []},\"testDoubleKey\": {\"Value\": 1.1,\"SettingType\": 3,\"PercentageRolloutItems\": [],\"TargetedRolloutRules\": []}}")

include ConfigCat

class ConfigFetcherMock < ConfigFetcher
  def initialize()
    @_call_count = 0
    @_configuration = TEST_JSON
  end
  def get_configuration_json()
    @_call_count = @_call_count + 1
    return @_configuration
  end
  def set_configuration_json(value)
    @_configuration = value
  end
  def close()
    # pass
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
    return TEST_JSON
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
    return @_value
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
