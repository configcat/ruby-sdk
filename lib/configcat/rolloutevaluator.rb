require 'configcat/user'
require 'digest'

module ConfigCat
  class RolloutEvaluator

    VALUE = "v"
    COMPARATOR = "t"
    COMPARISON_ATTRIBUTE = "a"
    COMPARISON_VALUE = "c"
    ROLLOUT_PERCENTAGE_ITEMS = "p"
    PERCENTAGE = "p"
    ROLLOUT_RULES = "r"

    def self.evaluate(key, user, default_value, config)
      if !user.equal?(nil) && !user.class.equal?(User)
        ConfigCat.logger.warn "User parameter is not an instance of User type."
        user = nil
      end
      setting_descriptor = config.fetch(key, nil)
      if setting_descriptor === nil
        ConfigCat.logger.warn "Could not find setting by key, returning default value. Key: #{key}"
        return default_value
      end
      if user === nil
        return setting_descriptor.fetch(VALUE, default_value)
      end
      rollout_rules = setting_descriptor.fetch(ROLLOUT_RULES, [])
      for rollout_rule in rollout_rules
        comparison_attribute = rollout_rule.fetch(COMPARISON_ATTRIBUTE)
        user_value = user.get_attribute(comparison_attribute)
        if user_value === nil || !user_value
          next
        end
        comparison_value = rollout_rule.fetch(COMPARISON_VALUE, nil)
        comparator = rollout_rule.fetch(COMPARATOR, nil)
        value = rollout_rule.fetch(VALUE, nil)
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
              if user_value.to_s.include?(comparison_value.to_s)
                return value
              end
            else
              if comparator == 3
                if !user_value.to_s.include?(comparison_value.to_s)
                  return value
                end
              end
            end
          end
        end
      end
      rollout_percentage_items = setting_descriptor.fetch(ROLLOUT_PERCENTAGE_ITEMS, [])
      if rollout_percentage_items.size > 0
        user_key = user.get_identifier()
        hash_candidate = ("%s%s" % [key, user_key]).encode("utf-8")
        hash_val = Digest::SHA1.hexdigest(hash_candidate)[0...7].to_i(base=16) % 100
        bucket = 0
        for rollout_percentage_item in rollout_percentage_items || []
          bucket += rollout_percentage_item.fetch(PERCENTAGE, 0)
          if hash_val < bucket
            return rollout_percentage_item.fetch(VALUE, nil)
          end
        end
      end
      return setting_descriptor.fetch(VALUE, default_value)
    end
  end

end

