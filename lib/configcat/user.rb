module ConfigCat
  # User Object. Contains user attributes which are used for evaluating targeting rules and percentage options.
  class User
    PREDEFINED = ["Identifier", "Email", "Country"]

    attr_reader :identifier

    # Initialize a User object.
    # Args:
    #     identifier: The unique identifier of the user or session (e.g. email address, primary key, session ID, etc.)
    #     email: Email address of the user.
    #     country: Country of the user.
    #     custom: Custom attributes of the user for advanced targeting rule definitions (e.g. role, subscription type, etc.)
    #     All comparators support string values as User Object attribute (in some cases they need to be provided in a
    #     specific format though, see below), but some of them also support other types of values. It depends on the
    #     comparator how the values will be handled. The following rules apply:
    #     Text-based comparators (EQUALS, IS_ONE_OF, etc.)
    #     * accept string values,
    #     * all other values are automatically converted to string
    #       (a warning will be logged but evaluation will continue as normal).
    #     SemVer-based comparators (IS_ONE_OF_SEMVER, LESS_THAN_SEMVER, GREATER_THAN_SEMVER, etc.)
    #     * accept string values containing a properly formatted, valid semver value,
    #     * all other values are considered invalid
    #       (a warning will be logged and the currently evaluated targeting rule will be skipped).
    #     Number-based comparators (EQUALS_NUMBER, LESS_THAN_NUMBER, GREATER_THAN_OR_EQUAL_NUMBER, etc.)
    #     * accept float values and all other numeric values which can safely be converted to float,
    #     * accept string values containing a properly formatted, valid float value,
    #     * all other values are considered invalid
    #       (a warning will be logged and the currently evaluated targeting rule will be skipped).
    #     Date time-based comparators (BEFORE_DATETIME / AFTER_DATETIME)
    #     * accept datetime values, which are automatically converted to a second-based Unix timestamp
    #       (datetime values with naive timezone are considered to be in UTC),
    #     * accept float values representing a second-based Unix timestamp
    #       and all other numeric values which can safely be converted to float,
    #     * accept string values containing a properly formatted, valid float value,
    #     * all other values are considered invalid
    #       (a warning will be logged and the currently evaluated targeting rule will be skipped).
    #     String array-based comparators (ARRAY_CONTAINS_ANY_OF / ARRAY_NOT_CONTAINS_ANY_OF)
    #     * accept arrays of strings,
    #     * accept string values containing a valid JSON string which can be deserialized to an array of strings,
    #     * all other values are considered invalid
    #       (a warning will be logged and the currently evaluated targeting rule will be skipped).
    def initialize(identifier, email: nil, country: nil, custom: nil)
      @identifier = (!identifier.equal?(nil)) ? identifier : ""
      @data = { "Identifier" => identifier, "Email" => email, "Country" => country }
      @custom = custom
    end

    def get_identifier
      return @identifier
    end

    def get_attribute(attribute)
      attribute = attribute.to_s
      return @data[attribute] if PREDEFINED.include?(attribute)
      return @custom[attribute] if @custom
      return nil
    end

    def to_s
      dump = {
        'Identifier': @identifier,
        'Email': @data['Email'],
        'Country': @data['Country']
      }
      dump.merge!(@custom) if @custom
      filtered_dump = dump.reject { |_, v| v.nil? }
      return JSON.generate(filtered_dump, ascii_only: false, separators: %w[, :])
    end
  end
end
