require 'spec_helper'
require 'configcat/configcache'
require_relative 'mocks'

RSpec.describe 'Hooks test', type: :feature do

  it "test init" do
    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new(
      on_client_ready: hook_callbacks.method(:on_client_ready),
      on_config_changed: hook_callbacks.method(:on_config_changed),
      on_flag_evaluated: hook_callbacks.method(:on_flag_evaluated),
      on_error: hook_callbacks.method(:on_error)
    )

    config_cache = ConfigCacheMock.new
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: config_cache,
                                                                    hooks: hooks))

    value = client.get_value('testStringKey', '')

    expect(value).to eq('testValue')
    expect(hook_callbacks.is_ready).to be true
    expect(hook_callbacks.is_ready_call_count).to eq(1)
    extended_config = TEST_OBJECT
    Config.extend_config_with_inline_salt_and_segment(extended_config)
    expect(hook_callbacks.changed_config).to eq(extended_config.fetch(FEATURE_FLAGS))
    expect(hook_callbacks.changed_config_call_count).to eq(1)
    expect(hook_callbacks.evaluation_details).not_to be nil
    expect(hook_callbacks.evaluation_details_call_count).to eq(1)
    expect(hook_callbacks.error).to be nil
    expect(hook_callbacks.error_call_count).to eq(0)

    client.close
  end

  it "test subscribe" do
    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new
    hooks.add_on_client_ready(hook_callbacks.method(:on_client_ready))
    hooks.add_on_config_changed(hook_callbacks.method(:on_config_changed))
    hooks.add_on_flag_evaluated(hook_callbacks.method(:on_flag_evaluated))
    hooks.add_on_error(hook_callbacks.method(:on_error))

    config_cache = ConfigCacheMock.new
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll,
                                                                    config_cache: config_cache,
                                                                    hooks: hooks))

    value = client.get_value('testStringKey', '')

    expect(value).to eq('testValue')
    expect(hook_callbacks.is_ready).to be true
    expect(hook_callbacks.is_ready_call_count).to eq(1)
    expect(hook_callbacks.changed_config).to eq(TEST_OBJECT.fetch(FEATURE_FLAGS))
    expect(hook_callbacks.changed_config_call_count).to eq(1)
    expect(hook_callbacks.evaluation_details).not_to be nil
    expect(hook_callbacks.evaluation_details_call_count).to eq(1)
    expect(hook_callbacks.error).to be nil
    expect(hook_callbacks.error_call_count).to eq(0)

    client.close
  end

  it "test_evaluation" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    hook_callbacks = HookCallbacks.new
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll))
    client.hooks.add_on_flag_evaluated(hook_callbacks.method(:on_flag_evaluated))

    client.force_refresh

    user = User.new("test@test1.com")
    value = client.get_value("testStringKey", "", user)
    expect(value).to eq("fake1")

    details = hook_callbacks.evaluation_details
    expect(details.value).to eq("fake1")
    expect(details.key).to eq("testStringKey")
    expect(details.variation_id).to eq("id1")
    expect(details.is_default_value).to be false
    expect(details.error).to be nil
    expect(details.matched_percentage_option).to be nil
    expect(details.matched_targeting_rule[SERVED_VALUE][VALUE][STRING_VALUE]).to eq("fake1")
    expect(details.user.to_s).to eq(user.to_s)
    now = Utils.get_utc_now_seconds_since_epoch
    expect(details.fetch_time.to_f).to be <= now
    expect(details.fetch_time.to_f + 1).to be >= now

    client.close
  end

  it "test_callback_exception" do
    WebMock.stub_request(:get, Regexp.new('https://.*')).to_return(status: 200, body: TEST_OBJECT_JSON, headers: {})

    hook_callbacks = HookCallbacks.new
    hooks = Hooks.new(
      on_client_ready: hook_callbacks.method(:callback_exception),
      on_config_changed: hook_callbacks.method(:callback_exception),
      on_flag_evaluated: hook_callbacks.method(:callback_exception),
      on_error: hook_callbacks.method(:callback_exception)
    )
    client = ConfigCatClient.get(TEST_SDK_KEY, ConfigCatOptions.new(polling_mode: PollingMode.manual_poll, hooks: hooks))

    client.force_refresh

    value = client.get_value("testStringKey", "")
    expect(value).to eq("testValue")

    value = client.get_value("", "default")
    expect(value).to eq("default")

    client.close
  end

end
