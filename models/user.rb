class User < Sequel::Model(:users)
  plugin :secure_password
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence [:name, :password, :password_confirmation, :email, :oauth_provider, :open_id]
    validates_format RegexPattern::Email, :email
    validates_format RegexPattern::Username, :name
  end

  def self.serialize id
    user = first :id=>id

    { :name=>user.name,
      :nickname=>user.nickname,
      :email=>user.email,
      :image_profile=>user.image_profile,
    }.to_json

  end
end