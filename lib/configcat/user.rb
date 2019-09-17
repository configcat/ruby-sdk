module ConfigCat

  class User
    #
    #    The user object for variation evaluation
    #

    PREDEFINED = ["identifier", "email", "country"]

    def initialize(identifier, email: nil, country: nil, custom: nil)
      @__identifier = identifier
      @__data = {"identifier" => identifier, "email" => email, "country" => country}
      @__custom = custom
    end

    def get_identifier()
      return @__identifier
    end

    def get_attribute(attribute)
      attribute = attribute.to_s.downcase()
      if PREDEFINED.include?(attribute)
        return @__data[attribute]
      end

      if !@__custom.equal?(nil)
        for customField in @__custom
          if customField.to_s.downcase() == attribute
            return @__custom[customField]
          end
        end
      end
      return nil
    end
  end

end
