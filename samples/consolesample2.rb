require 'configcat'

# Info level logging helps to inspect the feature flag evaluation process.
# Use the default warning level to avoid too detailed logging in your application.
ConfigCat.logger.level = Logger::INFO

# Initializing the ConfigCatClient with an SDK Key.
client = ConfigCat.create_client("PKDVCLf-Hq-h-kCzMp-L7Q/HhOWfwVtZ0mb30i9wi17GQ")

# Creating a user object to identify your user (optional).
userObject = ConfigCat::User.new("Some UserID", email: "configcat@example.com", custom: {
    'version': '1.0.0'
})

value = client.get_value("isPOCFeatureEnabled", "default value", userObject)
puts("'isPOCFeatureEnabled' value from ConfigCat: " + value.to_s)

value = client.get_value("isAwesomeFeatureEnabled", "default value")
puts("'isAwesomeFeatureEnabled' value from ConfigCat: " + value.to_s)

client.stop()
