module ConfigCat
  class EvaluationContext
    attr_accessor :key, :setting_type, :user, :visited_keys, :is_missing_user_object_logged, :is_missing_user_object_attribute_logged

    def initialize(key, setting_type, user, visited_keys = nil, is_missing_user_object_logged = false, is_missing_user_object_attribute_logged = false)
      @key = key
      @setting_type = setting_type
      @user = user
      @visited_keys = visited_keys || []
      @is_missing_user_object_logged = is_missing_user_object_logged
      @is_missing_user_object_attribute_logged = is_missing_user_object_attribute_logged
    end
  end
end
