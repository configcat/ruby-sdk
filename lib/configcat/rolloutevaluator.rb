require 'configcat/user'
require 'digest'
require 'semantic'

module ConfigCat
  class RolloutEvaluator
    COMPARATOR_TEXTS = ["IS ONE OF", "IS NOT ONE OF", "CONTAINS", "DOES NOT CONTAIN", "IS ONE OF (SemVer)", "IS NOT ONE OF (SemVer)", "< (SemVer)", "<= (SemVer)", "> (SemVer)", ">= (SemVer)", "= (Number)", "<> (Number)", "< (Number)", "<= (Number)", "> (Number)", ">= (Number)"]

    VALUE = "v"
    COMPARATOR = "t"
    COMPARISON_ATTRIBUTE = "a"
    COMPARISON_VALUE = "c"
    ROLLOUT_PERCENTAGE_ITEMS = "p"
    PERCENTAGE = "p"
    ROLLOUT_RULES = "r"

    def self.evaluate(key, user, default_value, config)
      ConfigCat.logger.info("Evaluating get_value('%s')." % key)

      setting_descriptor = config.fetch(key, nil)
      if setting_descriptor === nil
        ConfigCat.logger.error("Evaluating get_value('%s') failed. Value not found for key '%s' Returning default_value: [%s]. Here are the available keys: %s" % [key, key, default_value.to_s, config.to_a.join(", ")])
        return default_value
      end

      rollout_rules = setting_descriptor.fetch(ROLLOUT_RULES, [])
      rollout_percentage_items = setting_descriptor.fetch(ROLLOUT_PERCENTAGE_ITEMS, [])

      if !user.equal?(nil) && !user.class.equal?(User)
        ConfigCat.logger.warn("Evaluating get_value('%s'). User Object is not an instance of User type." % key)
        user = nil
      end
      if user === nil
        if rollout_rules.size > 0 || rollout_percentage_items.size > 0
          ConfigCat.logger.warn("Evaluating get_value('%s'). UserObject missing! You should pass a UserObject to get_value(), in order to make targeting work properly. Read more: https://configcat.com/docs/advanced/user-object/" % key)
        end
        return_value = setting_descriptor.fetch(VALUE, default_value)
        ConfigCat.logger.info("Returning [%s]" % return_value.to_s)
        return return_value
      end

      ConfigCat.logger.info("User object:\n%s" % user.to_s)

      # Evaluate targeting rules
      for rollout_rule in rollout_rules
        comparison_attribute = rollout_rule.fetch(COMPARISON_ATTRIBUTE)
        user_value = user.get_attribute(comparison_attribute)
        if user_value === nil || !user_value
          next
        end
        comparison_value = rollout_rule.fetch(COMPARISON_VALUE, nil)
        comparator = rollout_rule.fetch(COMPARATOR, nil)
        value = rollout_rule.fetch(VALUE, nil)

        # IS ONE OF
        if comparator == 0
          if comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
            return value
          end
        # IS NOT ONE OF
        elsif comparator == 1
          if !comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
            return value
          end
        # CONTAINS
        elsif comparator == 2
          if user_value.to_s.include?(comparison_value.to_s)
            return value
          end
        # DOES NOT CONTAIN
        elsif comparator == 3
          if !user_value.to_s.include?(comparison_value.to_s)
            return value
          end
        # IS ONE OF, IS NOT ONE OF (Semantic version)
        elsif (4 <= comparator) and (comparator <= 5)
          begin
            match = false
            user_value_version = Semantic::Version.new(user_value.to_s.strip())
            ((comparison_value.to_s.split(",").map { |x| x.strip() }).reject { |c| c.empty? }).each { |x|
              version = Semantic::Version.new(x)
              match = (user_value_version == version) || match
            }
            if match && comparator == 4 || !match && comparator == 5
              ConfigCat.logger.info(format_match_rule(comparison_attribute, comparator, comparison_value, value))
              return value
            end
          rescue ArgumentError => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, comparator, comparison_value, e.to_s))
            next
          end
        # LESS THAN, LESS THAN OR EQUALS TO, GREATER THAN, GREATER THAN OR EQUALS TO (Semantic version)
        elsif (6 <= comparator) and (comparator <= 9)
          begin
            user_value_version = Semantic::Version.new(user_value.to_s.strip())
            comparison_value_version = Semantic::Version.new(comparison_value.to_s.strip())
            if (comparator == 6 and user_value_version < comparison_value_version) or
               (comparator == 7 and user_value_version <= comparison_value_version) or
               (comparator == 8 and user_value_version > comparison_value_version) or
               (comparator == 9 and user_value_version >= comparison_value_version)
              ConfigCat.logger.info(format_match_rule(comparison_attribute, comparator, comparison_value, value))
              return value
            end
          rescue ArgumentError => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, comparator, comparison_value, e.to_s))
            next
          end
        elsif (10 <= comparator) and (comparator <= 15)
          begin
            user_value_float = Float(user_value.to_s.gsub(",", "."))
            comparison_value_float = Float(comparison_value.to_s.gsub(",", "."))
            if (comparator == 10 and user_value_float == comparison_value_float) or
               (comparator == 11 and user_value_float != comparison_value_float) or
               (comparator == 12 and user_value_float < comparison_value_float) or
               (comparator == 13 and user_value_float <= comparison_value_float) or
               (comparator == 14 and user_value_float > comparison_value_float) or
               (comparator == 15 and user_value_float >= comparison_value_float)
              ConfigCat.logger.info(format_match_rule(comparison_attribute, comparator, comparison_value, value))
              return value
            end
          rescue Exception => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, comparator, comparison_value, e.to_s))
            next
          end
        end
      end

      if rollout_percentage_items.size > 0
        user_key = user.get_identifier()
        hash_candidate = ("%s%s" % [key, user_key]).encode("utf-8")
        hash_val = Digest::SHA1.hexdigest(hash_candidate)[0...7].to_i(base=16) % 100
        bucket = 0
        for rollout_percentage_item in rollout_percentage_items || []
          bucket += rollout_percentage_item.fetch(PERCENTAGE, 0)
          if hash_val < bucket
            percentage_value = rollout_percentage_item.fetch(VALUE, nil)
            ConfigCat.logger.info("Evaluating %% options. Returning %s" % percentage_value)
            return percentage_value
          end
        end
      end
      return setting_descriptor.fetch(VALUE, default_value)
    end

    private

    def self.format_match_rule(comparison_attribute, comparator, comparison_value, value)
      return "Evaluating rule: [%s] [%s] [%s] => match, returning: %s" % [comparison_attribute, COMPARATOR_TEXTS[comparator], comparison_value, value]
    end

    def self.format_no_match_rule(comparison_attribute, comparator, comparison_value)
      return "Evaluating rule: [%s] [%s] [%s] => no match" % [comparison_attribute, COMPARATOR_TEXTS[comparator], comparison_value]
    end

    def self.format_validation_error_rule(comparison_attribute, comparator, comparison_value, error)
      return "Evaluating rule: [%s] [%s] [%s] => SKIP rule. Validation error: %s" % [comparison_attribute, COMPARATOR_TEXTS[comparator], comparison_value, error]
    end

  end

end

