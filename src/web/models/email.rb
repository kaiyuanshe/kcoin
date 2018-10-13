class UserEmail < Sequel::Model(:user_emails)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence %i[user_id email]
    validates_format RegexPattern::Email, :email, allow_nil: false
  end

end
