# ConfigCat SDK for Ruby
https://configcat.com  
ConfigCat SDK for Ruby provides easy integration for your application to ConfigCat.

ConfigCat is a feature flag and configuration management service that lets you separate releases from deployments. You can turn your features ON/OFF using <a href="http://app.configcat.com" target="_blank">ConfigCat Dashboard</a> even after they are deployed. ConfigCat lets you target specific groups of users based on region, email or any other custom user attribute.

ConfigCat is a <a href="https://configcat.com" target="_blank">hosted feature flag service</a>. Manage feature toggles across frontend, backend, mobile, desktop apps. <a href="https://configcat.com" target="_blank">Alternative to LaunchDarkly</a>. Management app + feature flag SDKs.

[![Build Status](https://travis-ci.com/configcat/ruby-sdk.svg?branch=master)](https://travis-ci.com/configcat/ruby-sdk)
[![Coverage Status](https://coveralls.io/repos/github/configcat/ruby-sdk/badge.svg?branch=master)](https://coveralls.io/github/configcat/ruby-sdk?branch=master)
[![Gem version](https://badge.fury.io/rb/configcat.svg)](https://rubygems.org/gems/configcat)
![License](https://img.shields.io/github/license/configcat/ruby-sdk.svg)

## Getting started

### 1. Install the package with `RubyGems`

```bash
gem install configcat
```

### 2. Import `configcat` to your application

```ruby
require 'configcat'
```

### 3. Go to <a href="https://app.configcat.com/connect" target="_blank">Connect your application</a> tab to get your *API Key*:
![API-KEY](https://raw.githubusercontent.com/ConfigCat/ruby-sdk/master/media/readme01.png  "API-KEY")

### 4. Create a *ConfigCat* client instance:

```ruby
configcat_client = ConfigCat.create_client("#YOUR-API-KEY#")
```
> We strongly recommend using the *ConfigCat Client* as a Singleton object in your application.

### 5. Get your setting value
```ruby
isMyAwesomeFeatureEnabled = configcat_client.get_value("isMyAwesomeFeatureEnabled", false)
if isMyAwesomeFeatureEnabled
    do_the_new_thing()
else
    do_the_old_thing()
end
```

### 6. Stop *ConfigCat* client on application exit
```ruby
configcat_client.stop()
```

## Getting user specific setting values with Targeting
Using this feature, you will be able to get different setting values for different users in your application by passing a `User Object` to the `get_value()` function.

Read more about [Targeting here](https://configcat.com/docs/advanced/targeting/).
```ruby
user = ConfigCat::User.new("#USER-IDENTIFIER#")

isMyAwesomeFeatureEnabled = configcat_client.get_value("isMyAwesomeFeatureEnabled", false, user)
if isMyAwesomeFeatureEnabled
    do_the_new_thing()
else
    do_the_old_thing()
end
```

## Sample/Demo app
* [Sample Console App](https://github.com/configcat/ruby-sdk/tree/master/samples/consolesample.rb)

## Polling Modes
The ConfigCat SDK supports 3 different polling mechanisms to acquire the setting values from ConfigCat. After latest setting values are downloaded, they are stored in the internal cache then all requests are served from there. Read more about Polling Modes and how to use them at [ConfigCat Docs](https://configcat.com/docs/sdk-reference/python/).

## Support
If you need help how to use this SDK feel free to to contact the ConfigCat Staff on https://configcat.com. We're happy to help.

## Contributing
Contributions are welcome.

## About ConfigCat
- [Official ConfigCat SDKs for other platforms](https://github.com/configcat)
- [Documentation](https://configcat.com/docs)
- [Blog](https://configcat.com/blog)
