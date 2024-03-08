module ConfigCat
  class EvaluationDetails
    attr_reader :key, :value, :variation_id, :fetch_time, :user, :is_default_value, :error,
                :matched_targeting_rule, :matched_percentage_option

    def initialize(key:, value:, variation_id: nil, fetch_time: nil, user: nil, is_default_value: false, error: nil,
                   matched_targeting_rule: nil, matched_percentage_option: nil)
      # Key of the feature flag or setting.
      @key = key

      # Evaluated value of the feature flag or setting.
      @value = value

      # Variation ID of the feature flag or setting (if available).
      @variation_id = variation_id

      # Time of last successful config download.
      @fetch_time = fetch_time

      # The User Object used for the evaluation (if available).
      @user = user

      # Indicates whether the default value passed to the setting evaluation methods like ConfigCatClient.get_value,
      # ConfigCatClient.get_value_details, etc. is used as the result of the evaluation.
      @is_default_value = is_default_value

      # Error message in case evaluation failed.
      @error = error

      # The targeting rule (if any) that matched during the evaluation and was used to return the evaluated value.
      @matched_targeting_rule = matched_targeting_rule

      # The percentage option (if any) that was used to select the evaluated value.
      @matched_percentage_option = matched_percentage_option
    end

    def self.from_error(key, value, error:, variation_id: nil)
      EvaluationDetails.new(key: key, value: value, variation_id: variation_id, is_default_value: true, error: error)
    end
  end
end
