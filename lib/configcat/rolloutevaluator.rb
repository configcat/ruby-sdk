require 'configcat/user'
require 'configcat/config'
require 'configcat/evaluationcontext'
require 'configcat/evaluationlogbuilder'
require 'digest'
require 'semantic'


module ConfigCat
  class RolloutEvaluator
    def initialize(log)
      @log = log
    end

    # :returns value, variation_id. matched_targeting_rule, matched_percentage_option, error
    def evaluate(key:, user:, default_value:, default_variation_id:, config:, log_builder:, visited_keys: nil)
      visited_keys ||= []
      is_root_flag_evaluation = visited_keys.empty?

      settings = config[FEATURE_FLAGS] || {}
      setting_descriptor = settings[key]

      if setting_descriptor.nil?
        error = "Failed to evaluate setting '#{key}' (the key was not found in config JSON). " \
                "Returning the `default_value` parameter that you specified in your application: '#{default_value}'. " \
                "Available keys: [#{settings.keys.map { |s| "'#{s}'" }.join(", ")}]."
        @log.error(1001, error)
        return default_value, default_variation_id, nil, nil, error
      end

      setting_type = setting_descriptor[SETTING_TYPE]
      salt = setting_descriptor[INLINE_SALT] || ''
      targeting_rules = setting_descriptor[TARGETING_RULES] || []
      percentage_rule_attribute = setting_descriptor[PERCENTAGE_RULE_ATTRIBUTE]

      context = EvaluationContext.new(key, setting_type, user, visited_keys)
      user_has_invalid_type = context.user && !context.user.is_a?(User)
      if user_has_invalid_type
        @log.warn(4001, "Cannot evaluate targeting rules and % options for setting '#{key}' " \
                        "(User Object is not an instance of User type). " \
                        "You should pass a User Object to the evaluation methods like `get_value()` " \
                        "in order to make targeting work properly. " \
                        "Read more: https://configcat.com/docs/advanced/user-object/")
        # We set the user to nil and won't log further missing user object warnings
        context.user = nil
        context.is_missing_user_object_logged = true
      end

      begin
        if log_builder && is_root_flag_evaluation
          log_builder.append("Evaluating '#{key}'")
          log_builder.append(" for User '#{context.user}'") if context.user
          log_builder.increase_indent
        end

        # Evaluate targeting rules (logically connected by OR)
        if log_builder && targeting_rules.any?
          log_builder.new_line("Evaluating targeting rules and applying the first match if any:")
        end
        targeting_rules.each do |targeting_rule|
          conditions = targeting_rule[CONDITIONS] || []

          if conditions.any?
            served_value = targeting_rule[SERVED_VALUE]
            value = Config.get_value(served_value, setting_type) if served_value

            # Evaluate targeting rule conditions (logically connected by AND)
            if evaluate_conditions(conditions, context, salt, config, log_builder, value)
              if served_value
                variation_id = served_value[VARIATION_ID] || default_variation_id
                log_builder.new_line("Returning '#{value}'.") if log_builder && is_root_flag_evaluation
                return [value, variation_id, targeting_rule, nil, nil]
              end
            else
              next
            end
          end

          # Evaluate percentage options of the targeting rule
          log_builder&.increase_indent
          percentage_options = targeting_rule.fetch(TARGETING_RULE_PERCENTAGE_OPTIONS, [])
          percentage_evaluation_result, percentage_value, percentage_variation_id, percentage_option =
            evaluate_percentage_options(percentage_options, context, percentage_rule_attribute,
                                        default_variation_id, log_builder)

          if percentage_evaluation_result
            if log_builder
              log_builder.decrease_indent
              log_builder.new_line("Returning '#{percentage_value}'.") if is_root_flag_evaluation
            end
            return [percentage_value, percentage_variation_id, targeting_rule, percentage_option, nil]
          else
            if log_builder
              log_builder.new_line('The current targeting rule is ignored and the evaluation continues with the next rule.')
              log_builder.decrease_indent
            end
            next
          end
        end

        # Evaluate percentage options
        percentage_options = setting_descriptor.fetch(PERCENTAGE_OPTIONS, [])
        percentage_evaluation_result, percentage_value, percentage_variation_id, percentage_option =
          evaluate_percentage_options(percentage_options, context, percentage_rule_attribute,
                                      default_variation_id, log_builder)

        if percentage_evaluation_result
          log_builder.new_line("Returning '#{percentage_value}'.") if log_builder && is_root_flag_evaluation
          return [percentage_value, percentage_variation_id, nil, percentage_option, nil]
        end

        return_value = Config.get_value(setting_descriptor, setting_type)
        return_variation_id = setting_descriptor.fetch(VARIATION_ID, default_variation_id)
        log_builder.new_line("Returning '#{return_value}'.") if log_builder && is_root_flag_evaluation
        return [return_value, return_variation_id, nil, nil, nil]
      rescue => e
        # During the recursive evaluation of a prerequisite flag, we propagate the exceptions
        # and let the root flag's evaluation code handle them.
        if !is_root_flag_evaluation
          raise e
        else
          error = "Failed to evaluate setting '#{key}'. (#{e}). " \
            "Returning the `%s` parameter that you specified in your application: '#{default_value}'."
          @log.error(2001, error)
          return [default_value, default_variation_id, nil, nil, error]
        end
      end
    end

    private

    # Calculates the SHA256 hash of the given value with the given salt and context_salt.
    def sha256(value_utf8, salt, context_salt)
      Digest::SHA256.hexdigest(value_utf8 + salt + context_salt)
    end

    def format_rule(comparison_attribute, comparator, comparison_value)
      comparator_text = COMPARATOR_TEXTS[comparator]
      "User.#{comparison_attribute} #{comparator_text} #{EvaluationLogBuilder.trunc_comparison_value_if_needed(comparator, comparison_value)}"
    end

    def user_attribute_value_to_string(value)
      return nil if value.nil?

      if value.is_a?(DateTime) || value.is_a?(Time)
        value = get_user_attribute_value_as_seconds_since_epoch(value)
      elsif value.is_a?(Array)
        value = get_user_attribute_value_as_string_list(value)
        # Convert the array to a JSON string
        return value.to_json
      end

      if value.is_a?(Float)
        return 'NaN' if value.nan?
        return 'Infinity' if value.infinite? == 1
        return '-Infinity' if value.infinite? == -1
        return value.to_s if value.to_s.include?('e')
        return value.to_i.to_s if value == value.to_i
      end

      value.to_s
    end

    def get_user_attribute_value_as_text(attribute_name, attribute_value, condition, key)
      return attribute_value if attribute_value.is_a?(String)

      @log.warn(3005, "Evaluation of condition (#{condition}) for setting '#{key}' may not produce the expected result " \
                      "(the User.#{attribute_name} attribute is not a string value, thus it was automatically converted to " \
                      "the string value '#{attribute_value}'). Please make sure that using a non-string value was intended.")
      user_attribute_value_to_string(attribute_value)
    end

    def convert_numeric_to_float(value)
      if value.is_a?(String)
        value = value.tr(',', '.')
        if value == 'NaN'
          return Float::NAN
        elsif value == 'Infinity'
          return Float::INFINITY
        elsif value == '-Infinity'
          return -Float::INFINITY
        end
      end

      Float(value)
    end

    def get_user_attribute_value_as_seconds_since_epoch(attribute_value)
      if attribute_value.is_a?(DateTime) || attribute_value.is_a?(Time)
        return Utils.get_seconds_since_epoch(attribute_value)
      end

      convert_numeric_to_float(attribute_value)
    end

    def get_user_attribute_value_as_string_list(attribute_value)
      if !attribute_value.is_a?(Array)
        attribute_value_list = JSON.parse(attribute_value)
      else
        attribute_value_list = attribute_value
      end

      # Ensure the result is an Array
      raise "Attribute value is not an Array" unless attribute_value_list.is_a?(Array)

      # Check if all items in the list are Strings
      attribute_value_list.each do |item|
        raise "All items in the list must be strings" unless item.is_a?(String)
      end

      attribute_value_list
    end

    # :returns evaluation error message
    def handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
      error = "cannot evaluate, the User.#{comparison_attribute} attribute is invalid (#{validation_error})"
      formatted_rule = format_rule(comparison_attribute, comparator, comparison_value)
      @log.warn(3004, "Cannot evaluate condition (#{formatted_rule}) for setting '#{key}' " \
                      "(#{validation_error}). Please check the User.#{comparison_attribute} attribute and make sure that its value corresponds to the " \
                      "comparison operator.")
      error
    end

    # :returns evaluation_result, percentage_value, percentage_variation_id, percentage_option
    def evaluate_percentage_options(percentage_options, context, percentage_rule_attribute, default_variation_id, log_builder)
      return [false, nil, nil, nil] if percentage_options.empty?

      user = context.user
      key = context.key

      if user.nil?
        unless context.is_missing_user_object_logged
          @log.warn(3001, "Cannot evaluate targeting rules and % options for setting '#{key}' " \
                          "(User Object is missing). " \
                          "You should pass a User Object to the evaluation methods like `get_value()` " \
                          "in order to make targeting work properly. " \
                          "Read more: https://configcat.com/docs/advanced/user-object/")
          context.is_missing_user_object_logged = true
        end

        log_builder&.new_line('Skipping % options because the User Object is missing.')
        return [false, nil, nil, nil]
      end

      user_attribute_name = percentage_rule_attribute || 'Identifier'
      if percentage_rule_attribute
        user_key = user.get_attribute(percentage_rule_attribute)
      else
        user_key = user.get_identifier
      end

      if percentage_rule_attribute && user_key.nil?
        unless context.is_missing_user_object_attribute_logged
          @log.warn(3003, "Cannot evaluate % options for setting '#{key}' " \
                          "(the User.#{percentage_rule_attribute} attribute is missing). You should set the User.#{percentage_rule_attribute} attribute in order to make " \
                          "targeting work properly. Read more: https://configcat.com/docs/advanced/user-object/")
          context.is_missing_user_object_attribute_logged = true
        end

        log_builder&.new_line("Skipping % options because the User.#{user_attribute_name} attribute is missing.")
        return [false, nil, nil, nil]
      end

      hash_candidate = "#{key}#{user_attribute_value_to_string(user_key)}".encode("utf-8")
      hash_val = Digest::SHA1.hexdigest(hash_candidate)[0...7].to_i(16) % 100

      bucket = 0
      index = 1
      percentage_options.each do |percentage_option|
        percentage = percentage_option[PERCENTAGE] || 0
        bucket += percentage
        if hash_val < bucket
          percentage_value = Config.get_value(percentage_option, context.setting_type)
          variation_id = percentage_option[VARIATION_ID] || default_variation_id
          if log_builder
            log_builder.new_line("Evaluating % options based on the User.#{user_attribute_name} attribute:")
            log_builder.new_line("- Computing hash in the [0..99] range from User.#{user_attribute_name} => #{hash_val} " \
                                 "(this value is sticky and consistent across all SDKs)")
            log_builder.new_line("- Hash value #{hash_val} selects % option #{index} (#{percentage}%), '#{percentage_value}'.")
          end
          return [true, percentage_value, variation_id, percentage_option]
        end
        index += 1
      end

      [false, nil, nil, nil]
    end

    def evaluate_conditions(conditions, context, salt, config, log_builder, value)
      first_condition = true
      condition_result = true
      error = nil

      conditions.each do |condition|
        user_condition = condition[USER_CONDITION]
        segment_condition = condition[SEGMENT_CONDITION]
        prerequisite_flag_condition = condition[PREREQUISITE_FLAG_CONDITION]

        if first_condition
          log_builder&.new_line('- IF ')
          log_builder&.increase_indent
          first_condition = false
        else
          log_builder&.new_line('AND ')
        end

        if user_condition
          result, error = evaluate_user_condition(user_condition, context, context.key, salt, log_builder)
          if log_builder && conditions.size > 1
            log_builder.append("=> #{result ? 'true' : 'false'}")
            log_builder.append(', skipping the remaining AND conditions') unless result
          end

          if !result || error
            condition_result = false
            break
          end
        elsif segment_condition
          result, error = evaluate_segment_condition(segment_condition, context, salt, log_builder)
          if log_builder
            if conditions.size > 1
              log_builder.append(' ') if error.nil?
              log_builder.append("=> #{result ? 'true' : 'false'}")
              log_builder.append(', skipping the remaining AND conditions') unless result
            elsif error.nil?
              log_builder.new_line
            end
          end

          if !result || error
            condition_result = false
            break
          end
        elsif prerequisite_flag_condition
          result = evaluate_prerequisite_flag_condition(prerequisite_flag_condition, context, config, log_builder)
          if log_builder
            if conditions.size > 1
              log_builder.append(" => #{result ? 'true' : 'false'}")
              log_builder.append(', skipping the remaining AND conditions') unless result
            elsif error.nil?
              log_builder.new_line
            end
          end

          if !result
            condition_result = false
            break
          end
        end
      end

      if log_builder
        log_builder.new_line if conditions.size > 1
        if error
          log_builder.append("THEN #{value ? "'#{value}'" : '% options'} => #{error}")
          log_builder.new_line("The current targeting rule is ignored and the evaluation continues with the next rule.")
        else
          log_builder.append("THEN #{value ? "'#{value}'" : "% options"} => #{condition_result ? "MATCH, applying rule" : "no match"}")
        end
        log_builder.decrease_indent if conditions.size > 0
      end

      condition_result
    end

    def evaluate_prerequisite_flag_condition(prerequisite_flag_condition, context, config, log_builder)
      prerequisite_key = prerequisite_flag_condition[PREREQUISITE_FLAG_KEY]
      prerequisite_comparator = prerequisite_flag_condition[PREREQUISITE_COMPARATOR]

      # Check if the prerequisite key exists
      settings = config.fetch(FEATURE_FLAGS, {})
      if prerequisite_key.nil? || settings[prerequisite_key].nil?
        raise "Prerequisite flag key is missing or invalid."
      end

      prerequisite_condition_result = false
      prerequisite_flag_setting_type = settings[prerequisite_key][SETTING_TYPE]
      prerequisite_comparison_value_type = Config.get_value_type(prerequisite_flag_condition)

      prerequisite_comparison_value = Config.get_value(prerequisite_flag_condition, prerequisite_flag_setting_type)

      # Type mismatch check
      if prerequisite_comparison_value_type != SettingType.to_type(prerequisite_flag_setting_type)
        raise "Type mismatch between comparison value '#{prerequisite_comparison_value}' and prerequisite flag '#{prerequisite_key}'"
      end

      prerequisite_condition = "Flag '#{prerequisite_key}' #{PREREQUISITE_COMPARATOR_TEXTS[prerequisite_comparator]} '#{prerequisite_comparison_value}'"

      # Circular dependency check
      visited_keys = context.visited_keys
      visited_keys.push(context.key)
      if visited_keys.include?(prerequisite_key)
        depending_flags = visited_keys.push(prerequisite_key).map { |s| "'#{s}'" }.join(' -> ')
        raise "Circular dependency detected between the following depending flags: #{depending_flags}."
      end

      if log_builder
        log_builder.append(prerequisite_condition)
        log_builder.new_line('(').increase_indent
        log_builder.new_line("Evaluating prerequisite flag '#{prerequisite_key}':")
      end

      prerequisite_value, _, _, _, _ = evaluate(key: prerequisite_key, user: context.user, default_value: nil, default_variation_id: nil,
                                                config: config, log_builder: log_builder, visited_keys: context.visited_keys)

      visited_keys.pop if visited_keys

      if log_builder
        log_builder.new_line("Prerequisite flag evaluation result: '#{prerequisite_value}'.")
        log_builder.new_line("Condition (Flag '#{prerequisite_key}' #{PREREQUISITE_COMPARATOR_TEXTS[prerequisite_comparator]} '#{prerequisite_comparison_value}') evaluates to ")
      end

      case prerequisite_comparator
      when PrerequisiteComparator::EQUALS
        prerequisite_condition_result = true if prerequisite_value == prerequisite_comparison_value
      when PrerequisiteComparator::NOT_EQUALS
        prerequisite_condition_result = true if prerequisite_value != prerequisite_comparison_value
      end

      if log_builder
        log_builder.append("#{prerequisite_condition_result ? 'true' : 'false'}.")
        log_builder.decrease_indent()&.new_line(')')
      end

      prerequisite_condition_result
    end

    def evaluate_segment_condition(segment_condition, context, salt, log_builder)
      user = context.user
      key = context.key

      segment = segment_condition[INLINE_SEGMENT]
      if segment.nil?
        raise 'Segment reference is invalid.'
      end

      segment_name = segment.fetch(SEGMENT_NAME, '')
      segment_comparator = segment_condition[SEGMENT_COMPARATOR]
      segment_conditions = segment.fetch(SEGMENT_CONDITIONS, [])

      if user.nil?
        unless context.is_missing_user_object_logged
          @log.warn(3001, "Cannot evaluate targeting rules and % options for setting '#{key}' " \
                          "(User Object is missing). " \
                          "You should pass a User Object to the evaluation methods like `get_value()` " \
                          "in order to make targeting work properly. " \
                          "Read more: https://configcat.com/docs/advanced/user-object/")
          context.is_missing_user_object_logged = true
        end
        log_builder&.append("User #{SEGMENT_COMPARATOR_TEXTS[segment_comparator]} '#{segment_name}' ")
        return [false, "cannot evaluate, User Object is missing"]
      end

      # IS IN SEGMENT, IS NOT IN SEGMENT
      if [SegmentComparator::IS_IN, SegmentComparator::IS_NOT_IN].include?(segment_comparator)
        if log_builder
          log_builder.append("User #{SEGMENT_COMPARATOR_TEXTS[segment_comparator]} '#{segment_name}'")
          log_builder.new_line("(").increase_indent
          log_builder.new_line("Evaluating segment '#{segment_name}':")
        end

        # Set initial condition result based on comparator
        segment_condition_result = segment_comparator == SegmentComparator::IS_IN

        # Evaluate segment conditions (logically connected by AND)
        first_segment_rule = true
        error = nil
        segment_conditions.each do |segment_condition|
          if first_segment_rule
            if log_builder
              log_builder.new_line('- IF ')
              log_builder.increase_indent
            end
            first_segment_rule = false
          else
            log_builder&.new_line('AND ')
          end

          result, error = evaluate_user_condition(segment_condition, context, segment_name, salt, log_builder)
          if log_builder
            log_builder.append("=> #{result ? 'true' : 'false'}")
            log_builder.append(', skipping the remaining AND conditions') unless result
          end

          unless result
            segment_condition_result = segment_comparator == SegmentComparator::IS_IN ? false : true
            break
          end
        end

        if log_builder
          log_builder.decrease_indent
          segment_evaluation_result = segment_comparator == SegmentComparator::IS_IN ? segment_condition_result : !segment_condition_result
          log_builder.new_line("Segment evaluation result: ")
          unless error
            log_builder.append("User IS#{segment_evaluation_result ? ' ' : ' NOT '}IN SEGMENT.")
          else
            log_builder.append("#{error}.")
          end

          log_builder.new_line("Condition (User #{SEGMENT_COMPARATOR_TEXTS[segment_comparator]} '#{segment_name}') ")

          unless error
            log_builder.append("evaluates to #{segment_condition_result ? 'true' : 'false'}.")
          else
            log_builder.append("failed to evaluate.")
          end

          log_builder.decrease_indent.new_line(')')
          log_builder.new_line if error
        end

        return [segment_condition_result, error]
      end

      [false, nil]
    end

    # :returns result of user condition, error
    def evaluate_user_condition(user_condition, context, context_salt, salt, log_builder)
      user = context.user
      key = context.key

      comparison_attribute = user_condition[COMPARISON_ATTRIBUTE]
      comparator = user_condition[COMPARATOR]
      comparison_value = user_condition[COMPARISON_VALUES[comparator]]
      condition = format_rule(comparison_attribute, comparator, comparison_value)
      error = nil

      if comparison_attribute.nil?
        raise "Comparison attribute name is missing."
      end

      log_builder&.append("#{condition} ")

      if user.nil?
        unless context.is_missing_user_object_logged
          @log.warn(3001, "Cannot evaluate targeting rules and % options for setting '#{key}' " \
                          "(User Object is missing). " \
                          "You should pass a User Object to the evaluation methods like `get_value()` " \
                          "in order to make targeting work properly. " \
                          "Read more: https://configcat.com/docs/advanced/user-object/")
          context.is_missing_user_object_logged = true
        end
        error = "cannot evaluate, User Object is missing"
        return [false, error]
      end

      user_value = user.get_attribute(comparison_attribute)
      if user_value.nil? || (user_value.is_a?(String) && user_value.empty?)
        @log.warn(3003, "Cannot evaluate condition (#{condition}) for setting '#{key}' " \
                        "(the User.#{comparison_attribute} attribute is missing). You should set the User.#{comparison_attribute} attribute in order to make " \
                        "targeting work properly. Read more: https://configcat.com/docs/advanced/user-object/")
        error = "cannot evaluate, the User.#{comparison_attribute} attribute is missing"
        return [false, error]
      end

      # IS ONE OF
      if comparator == Comparator::IS_ONE_OF
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        return true, error if comparison_value.include?(user_value)
      # IS NOT ONE OF
      elsif comparator == Comparator::IS_NOT_ONE_OF
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        return true, error unless comparison_value.include?(user_value)
      # CONTAINS ANY OF
      elsif comparator == Comparator::CONTAINS_ANY_OF
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        comparison_value.each do |comparison|
          return true, error if user_value.include?(comparison)
        end
      # NOT CONTAINS ANY OF
      elsif comparator == Comparator::NOT_CONTAINS_ANY_OF
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        return true, error unless comparison_value.any? { |comparison| user_value.include?(comparison) }
      # IS ONE OF, IS NOT ONE OF (Semantic version)
      elsif comparator >= Comparator::IS_ONE_OF_SEMVER && comparator <= Comparator::IS_NOT_ONE_OF_SEMVER
        begin
          match = false
          user_value_version = Semantic::Version.new(user_value.to_s.strip())
          ((comparison_value.map { |x| x.strip() }).reject { |c| c.empty? }).each { |x|
            version = Semantic::Version.new(x)
            match = (user_value_version == version) || match
          }
          if match && comparator == Comparator::IS_ONE_OF_SEMVER || !match && comparator == Comparator::IS_NOT_ONE_OF_SEMVER
            return true, error
          end
        rescue ArgumentError => e
          validation_error = "'#{user_value.to_s.strip}' is not a valid semantic version"
          error = self.handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end
      # LESS THAN, LESS THAN OR EQUAL TO, GREATER THAN, GREATER THAN OR EQUAL TO (Semantic version)
      elsif comparator >= Comparator::LESS_THAN_SEMVER && comparator <= Comparator::GREATER_THAN_OR_EQUAL_SEMVER
        begin
          user_value_version = Semantic::Version.new(user_value.to_s.strip)
          comparison_value_version = Semantic::Version.new(comparison_value.to_s.strip)
          if (comparator == Comparator::LESS_THAN_SEMVER && user_value_version < comparison_value_version) ||
             (comparator == Comparator::LESS_THAN_OR_EQUAL_SEMVER && user_value_version <= comparison_value_version) ||
             (comparator == Comparator::GREATER_THAN_SEMVER && user_value_version > comparison_value_version) ||
             (comparator == Comparator::GREATER_THAN_OR_EQUAL_SEMVER && user_value_version >= comparison_value_version)
            return true, error
          end
        rescue ArgumentError => e
          validation_error = "'#{user_value.to_s.strip}' is not a valid semantic version"
          error = self.handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end
      # =, <>, <, <=, >, >= (number)
      elsif comparator >= Comparator::EQUALS_NUMBER && comparator <= Comparator::GREATER_THAN_OR_EQUAL_NUMBER
        begin
          user_value_float = convert_numeric_to_float(user_value)
        rescue Exception => e
          validation_error = "'#{user_value}' is not a valid decimal number"
          error = self.handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end

        comparison_value_float = Float(comparison_value)
        if (comparator == Comparator::EQUALS_NUMBER && user_value_float == comparison_value_float) ||
           (comparator == Comparator::NOT_EQUALS_NUMBER && user_value_float != comparison_value_float) ||
           (comparator == Comparator::LESS_THAN_NUMBER && user_value_float < comparison_value_float) ||
           (comparator == Comparator::LESS_THAN_OR_EQUAL_NUMBER && user_value_float <= comparison_value_float) ||
           (comparator == Comparator::GREATER_THAN_NUMBER && user_value_float > comparison_value_float) ||
           (comparator == Comparator::GREATER_THAN_OR_EQUAL_NUMBER && user_value_float >= comparison_value_float)
          return true, error
        end
      # IS ONE OF (hashed)
      elsif comparator == Comparator::IS_ONE_OF_HASHED
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        if comparison_value.include?(sha256(user_value, salt, context_salt))
          return true, error
        end
      # IS NOT ONE OF (hashed)
      elsif comparator == Comparator::IS_NOT_ONE_OF_HASHED
        user_value = self.get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        unless comparison_value.include?(sha256(user_value, salt, context_salt))
          return true, error
        end
      # BEFORE, AFTER (UTC datetime)
      elsif comparator >= Comparator::BEFORE_DATETIME && comparator <= Comparator::AFTER_DATETIME
        begin
          user_value_float = get_user_attribute_value_as_seconds_since_epoch(user_value)
        rescue ArgumentError => e
          validation_error = "'#{user_value}' is not a valid Unix timestamp (number of seconds elapsed since Unix epoch)"
          error = self.handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end

        comparison_value_float = Float(comparison_value)
        if (comparator == Comparator::BEFORE_DATETIME && user_value_float < comparison_value_float) ||
          (comparator == Comparator::AFTER_DATETIME && user_value_float > comparison_value_float)
          return true, error
        end
      # EQUALS (hashed)
      elsif comparator == Comparator::EQUALS_HASHED
        user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        if sha256(user_value, salt, context_salt) == comparison_value
          return true, error
        end
      # NOT EQUALS (hashed)
      elsif comparator == Comparator::NOT_EQUALS_HASHED
        user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        if sha256(user_value, salt, context_salt) != comparison_value
          return true, error
        end
      # STARTS WITH ANY OF, NOT STARTS WITH ANY OF, ENDS WITH ANY OF, NOT ENDS WITH ANY OF (hashed)
      elsif comparator >= Comparator::STARTS_WITH_ANY_OF_HASHED && comparator <= Comparator::NOT_ENDS_WITH_ANY_OF_HASHED
        comparison_value.each do |comparison|
          underscore_index = comparison.index('_')
          length = comparison[0...underscore_index].to_i
          user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)

          if user_value.bytesize >= length
            comparison_string = comparison[(underscore_index + 1)..-1]
            if (comparator == Comparator::STARTS_WITH_ANY_OF_HASHED && sha256(user_value.byteslice(0...length), salt, context_salt) == comparison_string) ||
              (comparator == Comparator::ENDS_WITH_ANY_OF_HASHED && sha256(user_value.byteslice(-length..-1), salt, context_salt) == comparison_string)
              return true, error
            elsif (comparator == Comparator::NOT_STARTS_WITH_ANY_OF_HASHED && sha256(user_value.byteslice(0...length), salt, context_salt) == comparison_string) ||
              (comparator == Comparator::NOT_ENDS_WITH_ANY_OF_HASHED && sha256(user_value.byteslice(-length..-1), salt, context_salt) == comparison_string)
              return false, nil
            end
          end
        end

        # If no matches were found for the NOT_* conditions, then return true
        if [Comparator::NOT_STARTS_WITH_ANY_OF_HASHED, Comparator::NOT_ENDS_WITH_ANY_OF_HASHED].include?(comparator)
          return true, error
        end
      # ARRAY CONTAINS ANY OF, ARRAY NOT CONTAINS ANY OF (hashed)
      elsif comparator >= Comparator::ARRAY_CONTAINS_ANY_OF_HASHED && comparator <= Comparator::ARRAY_NOT_CONTAINS_ANY_OF_HASHED
        begin
          user_value_list = get_user_attribute_value_as_string_list(user_value)
        rescue Exception
          validation_error = "'#{user_value}' is not a valid string array"
          error = handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end

        hashed_user_values = user_value_list.map { |x| sha256(x, salt, context_salt) }
        if comparator == Comparator::ARRAY_CONTAINS_ANY_OF_HASHED
          comparison_value.each do |comparison|
            return true, error if hashed_user_values.include?(comparison)
          end
        else
          comparison_value.each do |comparison|
            return false, nil if hashed_user_values.include?(comparison)
          end
          return true, error
        end
      # EQUALS
      elsif comparator == Comparator::EQUALS
        user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        return true, error if user_value == comparison_value
        # NOT EQUALS
      elsif comparator == Comparator::NOT_EQUALS
        user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        return true, error if user_value != comparison_value
      # STARTS WITH ANY OF, NOT STARTS WITH ANY OF, ENDS WITH ANY OF, NOT ENDS WITH ANY OF
      elsif comparator >= Comparator::STARTS_WITH_ANY_OF && comparator <= Comparator::NOT_ENDS_WITH_ANY_OF
        user_value = get_user_attribute_value_as_text(comparison_attribute, user_value, condition, key)
        comparison_value.each do |comparison|
          if (comparator == Comparator::STARTS_WITH_ANY_OF && user_value.start_with?(comparison)) ||
            (comparator == Comparator::ENDS_WITH_ANY_OF && user_value.end_with?(comparison))
            return true, error
          elsif (comparator == Comparator::NOT_STARTS_WITH_ANY_OF && user_value.start_with?(comparison)) ||
            (comparator == Comparator::NOT_ENDS_WITH_ANY_OF && user_value.end_with?(comparison))
            return false, nil
          end
        end

        # If no matches were found for the NOT_* conditions, then return true
        if [Comparator::NOT_STARTS_WITH_ANY_OF, Comparator::NOT_ENDS_WITH_ANY_OF].include?(comparator)
          return true, error
        end
      # ARRAY CONTAINS ANY OF, ARRAY NOT CONTAINS ANY OF
      elsif comparator >= Comparator::ARRAY_CONTAINS_ANY_OF && comparator <= Comparator::ARRAY_NOT_CONTAINS_ANY_OF
        begin
          user_value_list = get_user_attribute_value_as_string_list(user_value)
        rescue Exception
          validation_error = "'#{user_value}' is not a valid string array"
          error = handle_invalid_user_attribute(comparison_attribute, comparator, comparison_value, key, validation_error)
          return false, error
        end

        if comparator == Comparator::ARRAY_CONTAINS_ANY_OF
          comparison_value.each do |comparison|
            return true, error if user_value_list.include?(comparison)
          end
        else
          comparison_value.each do |comparison|
            return false, nil if user_value_list.include?(comparison)
          end
          return true, error
        end
      end

      return false, error
    end
  end
end
