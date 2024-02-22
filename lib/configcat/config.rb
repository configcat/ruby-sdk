module ConfigCat
  CONFIG_FILE_NAME = 'config_v6'
  SERIALIZATION_FORMAT_VERSION = 'v2'

  # Config
  PREFERENCES = 'p'
  SEGMENTS = 's'
  FEATURE_FLAGS = 'f'

  # Preferences
  BASE_URL = 'u'
  REDIRECT = 'r'
  SALT = 's'

  # Segment
  SEGMENT_NAME = 'n'  # The first 4 characters of the Segment's name
  SEGMENT_CONDITIONS = 'r'  # The list of segment rule conditions (has a logical AND relation between the items).

  # Segment Condition (User Condition)
  COMPARISON_ATTRIBUTE = 'a'  # The attribute of the user object that should be used to evaluate this rule
  COMPARATOR = 'c'

  # Feature flag (Evaluation Formula)
  SETTING_TYPE = 't'  # 0 = bool, 1 = string, 2 = int, 3 = double
  PERCENTAGE_RULE_ATTRIBUTE = 'a'  # Percentage rule evaluation hashes this attribute of the User object to calculate the buckets
  TARGETING_RULES = 'r'  # Targeting Rules (Logically connected by OR)
  PERCENTAGE_OPTIONS = 'p'  # Percentage Options without conditions
  VALUE = 'v'
  VARIATION_ID = 'i'
  INLINE_SALT = 'inline_salt'

  # Targeting Rule (Evaluation Rule)
  CONDITIONS = 'c'
  SERVED_VALUE = 's'  # Value and Variation ID
  TARGETING_RULE_PERCENTAGE_OPTIONS = 'p'

  # Condition
  USER_CONDITION = 'u'
  SEGMENT_CONDITION = 's'  # Segment targeting rule
  PREREQUISITE_FLAG_CONDITION = 'p'  # Prerequisite flag targeting rule

  # Segment Condition
  SEGMENT_INDEX = 's'
  SEGMENT_COMPARATOR = 'c'
  INLINE_SEGMENT = 'inline_segment'

  # Prerequisite Flag Condition
  PREREQUISITE_FLAG_KEY = 'f'
  PREREQUISITE_COMPARATOR = 'c'

  # Percentage Option
  PERCENTAGE = 'p'

  # Value
  BOOL_VALUE = 'b'
  STRING_VALUE = 's'
  INT_VALUE = 'i'
  DOUBLE_VALUE = 'd'
  STRING_LIST_VALUE = 'l'
  UNSUPPORTED_VALUE = 'unsupported_value'

  module Config
    def self.is_type_mismatch(value, ruby_type)
      is_float_int_mismatch = \
        (value.is_a?(Float) && ruby_type == Integer) || \
          (value.is_a?(Integer) && ruby_type == Float)

      is_bool_mismatch = value.is_a?(TrueClass) && ruby_type == FalseClass || \
        value.is_a?(FalseClass) && ruby_type == TrueClass

      if value.class != ruby_type
        if !is_float_int_mismatch && !is_bool_mismatch
          return true
        end
      end

      return false
    end

    def self.get_value(dictionary, setting_type)
      value_descriptor = dictionary[VALUE]
      if value_descriptor.nil?
        raise 'Value is missing'
      end

      expected_value_type, expected_ruby_type = SettingType.get_type_info(setting_type)
      if expected_value_type.nil?
        raise 'Unsupported setting type'
      end

      value = value_descriptor[expected_value_type]
      if value.nil? || is_type_mismatch(value, expected_ruby_type)
        raise "Setting value is not of the expected type #{expected_ruby_type}"
      end

      return value
    end

    def self.get_value_type(dictionary)
      value = dictionary[VALUE]
      if !value.nil?
        if !value[BOOL_VALUE].nil?
          return TrueClass
        end
        if !value[STRING_VALUE].nil?
          return String
        end
        if !value[INT_VALUE].nil?
          return Integer
        end
        if !value[DOUBLE_VALUE].nil?
          return Float
        end
      end

      return nil
    end

    def self.extend_config_with_inline_salt_and_segment(config)
      """
      Adds the inline salt and segment to the config.
      When using flag overrides, the original salt and segment indexes may become invalid. Therefore, we copy the
      object references to the locations where they are referenced and use these references instead of the indexes.
      """
      salt = config.fetch(PREFERENCES, {}).fetch(SALT, '')
      segments = config[SEGMENTS] || []
      settings = config[FEATURE_FLAGS] || {}
      settings.each do |_, setting|
        next unless setting.is_a?(Hash)

        # add salt
        setting[INLINE_SALT] = salt

        # add segment to the segment conditions
        targeting_rules = setting[TARGETING_RULES] || []
        targeting_rules.each do |targeting_rule|
          conditions = targeting_rule[CONDITIONS] || []
          conditions.each do |condition|
            segment_condition = condition[SEGMENT_CONDITION]
            if segment_condition
              segment_index = segment_condition[SEGMENT_INDEX]
              segment = segments[segment_index]
              segment_condition[INLINE_SEGMENT] = segment
            end
          end
        end
      end
    end
  end

  class SettingType
    BOOL = 0
    STRING = 1
    INT = 2
    DOUBLE = 3

    @@setting_type_mapping = {
      SettingType::BOOL => [BOOL_VALUE, TrueClass],
      SettingType::STRING => [STRING_VALUE, String],
      SettingType::INT => [INT_VALUE, Integer],
      SettingType::DOUBLE => [DOUBLE_VALUE, Float]
    }

    def self.get_type_info(setting_type)
      return @@setting_type_mapping[setting_type] || [nil, nil]
    end

    def self.from_type(object_type)
      if object_type == TrueClass || object_type == FalseClass
        return BOOL
      elsif object_type == String
        return STRING
      elsif object_type == Integer
        return INT
      elsif object_type == Float
        return DOUBLE
      end

      return nil
    end

    def self.to_type(setting_type)
      return get_type_info(setting_type)[1]
    end

    def self.to_value_type(setting_type)
      return get_type_info(setting_type)[0]
    end
  end

  module PrerequisiteComparator
    EQUALS = 0
    NOT_EQUALS = 1
  end

  module SegmentComparator
    IS_IN = 0
    IS_NOT_IN = 1
  end

  module Comparator
    IS_ONE_OF = 0
    IS_NOT_ONE_OF = 1
    CONTAINS_ANY_OF = 2
    NOT_CONTAINS_ANY_OF = 3
    IS_ONE_OF_SEMVER = 4
    IS_NOT_ONE_OF_SEMVER = 5
    LESS_THAN_SEMVER = 6
    LESS_THAN_OR_EQUAL_SEMVER = 7
    GREATER_THAN_SEMVER = 8
    GREATER_THAN_OR_EQUAL_SEMVER = 9
    EQUALS_NUMBER = 10
    NOT_EQUALS_NUMBER = 11
    LESS_THAN_NUMBER = 12
    LESS_THAN_OR_EQUAL_NUMBER = 13
    GREATER_THAN_NUMBER = 14
    GREATER_THAN_OR_EQUAL_NUMBER = 15
    IS_ONE_OF_HASHED = 16
    IS_NOT_ONE_OF_HASHED = 17
    BEFORE_DATETIME = 18
    AFTER_DATETIME = 19
    EQUALS_HASHED = 20
    NOT_EQUALS_HASHED = 21
    STARTS_WITH_ANY_OF_HASHED = 22
    NOT_STARTS_WITH_ANY_OF_HASHED = 23
    ENDS_WITH_ANY_OF_HASHED = 24
    NOT_ENDS_WITH_ANY_OF_HASHED = 25
    ARRAY_CONTAINS_ANY_OF_HASHED = 26
    ARRAY_NOT_CONTAINS_ANY_OF_HASHED = 27
    EQUALS = 28
    NOT_EQUALS = 29
    STARTS_WITH_ANY_OF = 30
    NOT_STARTS_WITH_ANY_OF = 31
    ENDS_WITH_ANY_OF = 32
    NOT_ENDS_WITH_ANY_OF = 33
    ARRAY_CONTAINS_ANY_OF = 34
    ARRAY_NOT_CONTAINS_ANY_OF = 35
  end

  COMPARATOR_TEXTS = [
    'IS ONE OF',                  # IS_ONE_OF
    'IS NOT ONE OF',              # IS_NOT_ONE_OF
    'CONTAINS ANY OF',            # CONTAINS_ANY_OF
    'NOT CONTAINS ANY OF',        # NOT_CONTAINS_ANY_OF
    'IS ONE OF',                  # IS_ONE_OF_SEMVER
    'IS NOT ONE OF',              # IS_NOT_ONE_OF_SEMVER
    '<',                          # LESS_THAN_SEMVER
    '<=',                         # LESS_THAN_OR_EQUAL_SEMVER
    '>',                          # GREATER_THAN_SEMVER
    '>=',                         # GREATER_THAN_OR_EQUAL_SEMVER
    '=',                          # EQUALS_NUMBER
    '!=',                         # NOT_EQUALS_NUMBER
    '<',                          # LESS_THAN_NUMBER
    '<=',                         # LESS_THAN_OR_EQUAL_NUMBER
    '>',                          # GREATER_THAN_NUMBER
    '>=',                         # GREATER_THAN_OR_EQUAL_NUMBER
    'IS ONE OF',                  # IS_ONE_OF_HASHED
    'IS NOT ONE OF',              # IS_NOT_ONE_OF_HASHED
    'BEFORE',                     # BEFORE_DATETIME
    'AFTER',                      # AFTER_DATETIME
    'EQUALS',                     # EQUALS_HASHED
    'NOT EQUALS',                 # NOT_EQUALS_HASHED
    'STARTS WITH ANY OF',         # STARTS_WITH_ANY_OF_HASHED
    'NOT STARTS WITH ANY OF',     # NOT_STARTS_WITH_ANY_OF_HASHED
    'ENDS WITH ANY OF',           # ENDS_WITH_ANY_OF_HASHED
    'NOT ENDS WITH ANY OF',       # NOT_ENDS_WITH_ANY_OF_HASHED
    'ARRAY CONTAINS ANY OF',      # ARRAY_CONTAINS_ANY_OF_HASHED
    'ARRAY NOT CONTAINS ANY OF',  # ARRAY_NOT_CONTAINS_ANY_OF_HASHED
    'EQUALS',                     # EQUALS
    'NOT EQUALS',                 # NOT_EQUALS
    'STARTS WITH ANY OF',         # STARTS_WITH_ANY_OF
    'NOT STARTS WITH ANY OF',     # NOT_STARTS_WITH_ANY_OF
    'ENDS WITH ANY OF',           # ENDS_WITH_ANY_OF
    'NOT ENDS WITH ANY OF',       # NOT_ENDS_WITH_ANY_OF
    'ARRAY CONTAINS ANY OF',      # ARRAY_CONTAINS_ANY_OF
    'ARRAY NOT CONTAINS ANY OF'   # ARRAY_NOT_CONTAINS_ANY_OF
  ]

  COMPARISON_VALUES = [
    STRING_LIST_VALUE,  # IS_ONE_OF
    STRING_LIST_VALUE,  # IS_NOT_ONE_OF
    STRING_LIST_VALUE,  # CONTAINS_ANY_OF
    STRING_LIST_VALUE,  # NOT_CONTAINS_ANY_OF
    STRING_LIST_VALUE,  # IS_ONE_OF_SEMVER
    STRING_LIST_VALUE,  # IS_NOT_ONE_OF_SEMVER
    STRING_VALUE,       # LESS_THAN_SEMVER
    STRING_VALUE,       # LESS_THAN_OR_EQUAL_SEMVER
    STRING_VALUE,       # GREATER_THAN_SEMVER
    STRING_VALUE,       # GREATER_THAN_OR_EQUAL_SEMVER
    DOUBLE_VALUE,       # EQUALS_NUMBER
    DOUBLE_VALUE,       # NOT_EQUALS_NUMBER
    DOUBLE_VALUE,       # LESS_THAN_NUMBER
    DOUBLE_VALUE,       # LESS_THAN_OR_EQUAL_NUMBER
    DOUBLE_VALUE,       # GREATER_THAN_NUMBER
    DOUBLE_VALUE,       # GREATER_THAN_OR_EQUAL_NUMBER
    STRING_LIST_VALUE,  # IS_ONE_OF_HASHED
    STRING_LIST_VALUE,  # IS_NOT_ONE_OF_HASHED
    DOUBLE_VALUE,       # BEFORE_DATETIME
    DOUBLE_VALUE,       # AFTER_DATETIME
    STRING_VALUE,       # EQUALS_HASHED
    STRING_VALUE,       # NOT_EQUALS_HASHED
    STRING_LIST_VALUE,  # STARTS_WITH_ANY_OF_HASHED
    STRING_LIST_VALUE,  # NOT_STARTS_WITH_ANY_OF_HASHED
    STRING_LIST_VALUE,  # ENDS_WITH_ANY_OF_HASHED
    STRING_LIST_VALUE,  # NOT_ENDS_WITH_ANY_OF_HASHED
    STRING_LIST_VALUE,  # ARRAY_CONTAINS_ANY_OF_HASHED
    STRING_LIST_VALUE,  # ARRAY_NOT_CONTAINS_ANY_OF_HASHED
    STRING_VALUE,       # EQUALS
    STRING_VALUE,       # NOT_EQUALS
    STRING_LIST_VALUE,  # STARTS_WITH_ANY_OF
    STRING_LIST_VALUE,  # NOT_STARTS_WITH_ANY_OF
    STRING_LIST_VALUE,  # ENDS_WITH_ANY_OF
    STRING_LIST_VALUE,  # NOT_ENDS_WITH_ANY_OF
    STRING_LIST_VALUE,  # ARRAY_CONTAINS_ANY_OF
    STRING_LIST_VALUE   # ARRAY_NOT_CONTAINS_ANY_OF
  ]
  SEGMENT_COMPARATOR_TEXTS = ['IS IN SEGMENT', 'IS NOT IN SEGMENT']
  PREREQUISITE_COMPARATOR_TEXTS = ['EQUALS', 'DOES NOT EQUAL']
end
