class User < Sequel::Model(:users)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence [:login, :email, :oauth_provider]
    validates_format RegexPattern::Email, :email, {:allow_nil => true}
    validates_format RegexPattern::Username, :login
  end

  def self.serialize id
    user = first :id=>id

    { :login=>user.login,
      :name=>user.name,
      :email=>user.email,
      :avatar_url=>user.avatar_url,
    }.to_json

  end

  many_to_many :roles
  many_to_many :projects
  one_to_many :oauth
end