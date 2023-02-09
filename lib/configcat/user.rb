module ConfigCat

  class User
    #
    #    The user object for variation evaluation
    #

    PREDEFINED = ["Identifier", "Email", "Country"]

    attr_reader :identifier

    def initialize(identifier, email: nil, country: nil, custom: nil)
      @identifier = (!identifier.equal?(nil)) ? identifier : ""
      @data = { "Identifier" => identifier, "Email" => email, "Country" => country}
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
        'Country': @data['Country'],
        'Custom': @custom,
      }
      return dump.to_json
    end
  end

end
