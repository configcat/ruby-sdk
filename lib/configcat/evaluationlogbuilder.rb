module ConfigCat
  class EvaluationLogBuilder
    def initialize
      @indent_level = 0
      @text = ''
    end

    def self.trunc_comparison_value_if_needed(comparator, comparison_value)
      if [
        Comparator::IS_ONE_OF_HASHED,
        Comparator::IS_NOT_ONE_OF_HASHED,
        Comparator::EQUALS_HASHED,
        Comparator::NOT_EQUALS_HASHED,
        Comparator::STARTS_WITH_ANY_OF_HASHED,
        Comparator::NOT_STARTS_WITH_ANY_OF_HASHED,
        Comparator::ENDS_WITH_ANY_OF_HASHED,
        Comparator::NOT_ENDS_WITH_ANY_OF_HASHED,
        Comparator::ARRAY_CONTAINS_ANY_OF_HASHED,
        Comparator::ARRAY_NOT_CONTAINS_ANY_OF_HASHED
      ].include?(comparator)
        if comparison_value.is_a?(Array)
          length = comparison_value.length
          if length > 1
            return "[<#{length} hashed values>]"
          end
          return "[<#{length} hashed value>]"
        end

        return "'<hashed value>'"
      end

      if comparison_value.is_a?(Array)
        length_limit = 10
        length = comparison_value.length
        if length > length_limit
          remaining = length - length_limit
          more_text = remaining == 1 ? "<1 more value>" : "<#{remaining} more values>"

          return comparison_value.first(length_limit).to_s[0..-2] + ', ... ' + more_text + ']'
        end

        return comparison_value.to_s
      end

      if [Comparator::BEFORE_DATETIME, Comparator::AFTER_DATETIME].include?(comparator)
        time = get_date_time(comparison_value)
        return "'#{comparison_value}' (#{time.strftime('%Y-%m-%dT%H:%M:%S.%f')[0..-4]}Z UTC)"
      end

      "'#{comparison_value.to_s}'"
    end

    def increase_indent
      @indent_level += 1
      self
    end

    def decrease_indent
      @indent_level = [@indent_level - 1, 0].max
      self
    end

    def append(text)
      @text += text
      self
    end

    def new_line(text = nil)
      @text += "\n" + '  ' * @indent_level
      @text += text if text
      self
    end

    def to_s
      @text
    end
  end
end
