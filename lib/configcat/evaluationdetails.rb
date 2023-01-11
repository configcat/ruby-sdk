module ConfigCat

class EvaluationDetails
  attr_reader :key, :value, :variation_id, :fetch_time, :user, :is_default_value, :error,
              :matched_evaluation_rule, :matched_evaluation_percentage_rule

  def initialize(key:, value:, variation_id: nil, fetch_time: nil, user: nil, is_default_value: false, error: nil,
                 matched_evaluation_rule: nil, matched_evaluation_percentage_rule: nil)
    @key = key
    @value = value
    @variation_id = variation_id
    @fetch_time = fetch_time
    @user = user
    @is_default_value = is_default_value
    @error = error
    @matched_evaluation_rule = matched_evaluation_rule
    @matched_evaluation_percentage_rule = matched_evaluation_percentage_rule
  end

  def self.from_error(key, value, error:, variation_id: nil)
    EvaluationDetails.new(key: key, value: value, variation_id: variation_id, is_default_value: true, error: error)
  end
end

end
