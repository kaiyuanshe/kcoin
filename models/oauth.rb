class Oauth < Sequel::Model(:oauth)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence %i[login email oauth_provider]
    validates_format RegexPattern::Email, :email, allow_nil: true
    validates_format RegexPattern::Username, :login
  end

  def self.serialize(id)
    oauth = first id: id

    {login: oauth.login,
     name: oauth.name,
     email: oauth.email,
     avatar_url: oauth.avatar_url}.to_json
  end
end
