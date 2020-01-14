require 'configcat'

# Initializing the ConfigCatClient with an API Key.
client = ConfigCat.create_client("PKDVCLf-Hq-h-kCzMp-L7Q/HhOWfwVtZ0mb30i9wi17GQ")

# Setting the log level to Info to show detailed feature flag evaluation.
ConfigCat.logger.level = Logger::INFO

# Creating a user object to identify your user (optional).
userObject = ConfigCat::User.new("Some UserID", email: "configcat@examle.com", custom: {
    'ver': '1.0.0'
})

value = client.get_value("isPOCFeatureEnabled", "default value", userObject)
puts("'isPOCFeatureEnabled' value from ConfigCat: " + value.to_s)