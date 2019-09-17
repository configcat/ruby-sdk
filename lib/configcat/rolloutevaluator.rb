require 'configcat/user'
require 'digest'

module ConfigCat
  class RolloutEvaluator

    def self.evaluate(key, user, default_value, config)
      if !user.equal?(nil) && !user.class.equal?(User)
        # TODO: logging is needed
        # log.warning("User parameter is not an instance of User type.")
        user = nil
      end
      setting_descriptor = config.fetch(key, nil)
      if setting_descriptor === nil
        # log.warning("Could not find setting by key, returning default value. Key: [%s]", key)
        return default_value
      end
      if user === nil
        return setting_descriptor.fetch("Value", default_value)
      end
      rollout_rules = setting_descriptor.fetch("RolloutRules", [])
      for rollout_rule in rollout_rules
        comparison_attribute = rollout_rule.fetch("ComparisonAttribute")
        user_value = user.get_attribute(comparison_attribute)
        if user_value === nil || !user_value
          next
        end
        comparison_value = rollout_rule.fetch("ComparisonValue", nil)
        comparator = rollout_rule.fetch("Comparator", nil)
        value = rollout_rule.fetch("Value", nil)
        if comparator == 0
          if comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
            return value
          end
        else
          if comparator == 1
            if !comparison_value.to_s.split(",").map { |x| x.strip() }.include?(user_value.to_s)
              return value
            end
          else
            if comparator == 2
              if user_value.to_s.__contains__(comparison_value.to_s)
                return value
              end
            else
              if comparator == 3
                if !user_value.to_s.__contains__(comparison_value.to_s)
                  return value
                end
              end
            end
          end
        end
      end
      rollout_percentage_items = setting_descriptor.fetch("RolloutPercentageItems", [])
      if rollout_percentage_items.size > 0
        user_key = user.get_identifier()
        hash_candidate = ("%s%s" % [key, user_key]).encode("utf-8")
        hash_val = Digest::SHA256.hexdigest(hash_candidate)[0...7].to_i(base=16) % 100
        bucket = 0
        for rollout_percentage_item in rollout_percentage_items || []
          bucket += rollout_percentage_item.fetch("Percentage", 0)
          if hash_val < bucket
            return rollout_percentage_item.fetch("Value", nil)
          end
        end
      end
      return setting_descriptor.fetch("Value", default_value)
    end
  end

end

