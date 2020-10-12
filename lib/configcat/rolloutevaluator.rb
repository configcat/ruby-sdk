require 'configcat/user'
require 'configcat/constants'
require 'digest'
require 'semantic'

module ConfigCat
  class RolloutEvaluator
    COMPARATOR_TEXTS = ["IS ONE OF", "IS NOT ONE OF", "CONTAINS", "DOES NOT CONTAIN", "IS ONE OF (SemVer)", "IS NOT ONE OF (SemVer)", "< (SemVer)", "<= (SemVer)", "> (SemVer)", ">= (SemVer)", "= (Number)", "<> (Number)", "< (Number)", "<= (Number)", "> (Number)", ">= (Number)"]

    def self.evaluate(key, user, default_value, default_variation_id, config)
      ConfigCat.logger.info("Evaluating get_value('%s')." % key)

      feature_flags = config.fetch(FEATURE_FLAGS, nil)
      if feature_flags === nil
        ConfigCat.logger.error("Evaluating get_value('%s') failed. Value not found for key '%s' Returning default_value: [%s]." % [key, key, default_value.to_s])
        return default_value, default_variation_id
      end

      setting_descriptor = feature_flags.fetch(key, nil)
      if setting_descriptor === nil
        ConfigCat.logger.error("Evaluating get_value('%s') failed. Value not found for key '%s'. Returning default_value: [%s]. Here are the available keys: %s" % [key, key, default_value.to_s, feature_flags.keys.join(", ")])
        return default_value, default_variation_id
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
        return_variation_id = setting_descriptor.fetch(VARIATION_ID, default_variation_id)
        ConfigCat.logger.info("Returning [%s]" % return_value.to_s)
        return return_value, return_variation_id
      end

      ConfigCat.logger.info("User object:\n%s" % user.to_s)

      # Evaluate targeting rules
      for rollout_rule in rollout_rules
        comparison_attribute = rollout_rule.fetch(COMPARISON_ATTRIBUTE)
        comparison_value = rollout_rule.fetch(COMPARISON_VALUE, nil)
        comparator = rollout_rule.fetch(COMPARATOR, nil)

        user_value = user.get_attribute(comparison_attribute)
        if user_value === nil || !user_value
          ConfigCat.logger.info(format_no_match_rule(comparison_attribute, user_value, comparator, comparison_value))
          next
        end

        value = rollout_rule.fetch(VALUE, nil)
        variation_id = rollout_rule.fetch(VARIATION_ID, default_variation_id)

        # IS ONE OF
        if comparator == 0
          if comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        # IS NOT ONE OF
        elsif comparator == 1
          if !comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        # CONTAINS
        elsif comparator == 2
          if user_value.to_s.include?(comparison_value.to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        # DOES NOT CONTAIN
        elsif comparator == 3
          if !user_value.to_s.include?(comparison_value.to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        # IS ONE OF, IS NOT ONE OF (Semantic version)
        elsif (4 <= comparator) && (comparator <= 5)
          begin
            match = false
            user_value_version = Semantic::Version.new(user_value.to_s.strip())
            ((comparison_value.to_s.split(",").map { |x| x.strip() }).reject { |c| c.empty? }).each { |x|
              version = Semantic::Version.new(x)
              match = (user_value_version == version) || match
            }
            if match && comparator == 4 || !match && comparator == 5
              ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
              return value, variation_id
            end
          rescue ArgumentError => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, user_value, comparator, comparison_value, e.to_s))
            next
          end
        # LESS THAN, LESS THAN OR EQUALS TO, GREATER THAN, GREATER THAN OR EQUALS TO (Semantic version)
        elsif (6 <= comparator) && (comparator <= 9)
          begin
            user_value_version = Semantic::Version.new(user_value.to_s.strip())
            comparison_value_version = Semantic::Version.new(comparison_value.to_s.strip())
            if (comparator == 6 && user_value_version < comparison_value_version) ||
               (comparator == 7 && user_value_version <= comparison_value_version) ||
               (comparator == 8 && user_value_version > comparison_value_version) ||
               (comparator == 9 && user_value_version >= comparison_value_version)
              ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
              return value, variation_id
            end
          rescue ArgumentError => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, user_value, comparator, comparison_value, e.to_s))
            next
          end
        elsif (10 <= comparator) && (comparator <= 15)
          begin
            user_value_float = Float(user_value.to_s.gsub(",", "."))
            comparison_value_float = Float(comparison_value.to_s.gsub(",", "."))
            if (comparator == 10 && user_value_float == comparison_value_float) ||
               (comparator == 11 && user_value_float != comparison_value_float) ||
               (comparator == 12 && user_value_float < comparison_value_float) ||
               (comparator == 13 && user_value_float <= comparison_value_float) ||
               (comparator == 14 && user_value_float > comparison_value_float) ||
               (comparator == 15 && user_value_float >= comparison_value_float)
              ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
              return value, variation_id
            end
          rescue Exception => e
            ConfigCat.logger.warn(format_validation_error_rule(comparison_attribute, user_value, comparator, comparison_value, e.to_s))
            next
          end
        # IS ONE OF (Sensitive)
        elsif comparator == 16
          if comparison_value.to_s.split(",").map { |x| x.strip() }.include?(Digest::SHA1.hexdigest(user_value).to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        # IS NOT ONE OF (Sensitive)
        elsif comparator == 17
          if !comparison_value.to_s.split(",").map { |x| x.strip() }.include?(Digest::SHA1.hexdigest(user_value).to_s)
            ConfigCat.logger.info(format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value))
            return value, variation_id
          end
        end
        ConfigCat.logger.info(format_no_match_rule(comparison_attribute, user_value, comparator, comparison_value))
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
            variation_id = rollout_percentage_item.fetch(VARIATION_ID, default_variation_id)
            ConfigCat.logger.info("Evaluating %% options. Returning %s" % percentage_value)
            return percentage_value, variation_id
          end
        end
      end
      return_value = setting_descriptor.fetch(VALUE, default_value)
      return_variation_id = setting_descriptor.fetch(VARIATION_ID, default_variation_id)
      ConfigCat.logger.info("Returning %s" % return_value)
      return return_value, return_variation_id
    end

    private

    def self.format_match_rule(comparison_attribute, user_value, comparator, comparison_value, value)
      return "Evaluating rule: [%s:%s] [%s] [%s] => match, returning: %s" % [comparison_attribute, user_value, COMPARATOR_TEXTS[comparator], comparison_value, value]
    end

    def self.format_no_match_rule(comparison_attribute, user_value, comparator, comparison_value)
      return "Evaluating rule: [%s:%s] [%s] [%s] => no match" % [comparison_attribute, user_value, COMPARATOR_TEXTS[comparator], comparison_value]
    end

    def self.format_validation_error_rule(comparison_attribute, user_value, comparator, comparison_value, error)
      return "Evaluating rule: [%s:%s] [%s] [%s] => SKIP rule. Validation error: %s" % [comparison_attribute, user_value, COMPARATOR_TEXTS[comparator], comparison_value, error]
    end

  end

end

