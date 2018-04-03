module UserAppHelpers

  def current_user(decode_token)
    # If decode_token is true then decode jwt token,
    # If not, we assume that the user id is in the header
    # return class instance that define the type of user
    if decode_token
      token = bearer_token
      begin
        payload, header = JWT.decode(token, settings.verify_key, true, {:algorithm => 'RS256'})

        exp = header['exp']

        return GuestUser.new if exp.nil?

        exp = Time.at(exp.to_i)

        return GuestUser.new(:expired=>true) if Time.now > exp

        id = payload['user_id']

      rescue JWT::DecodeError
        return GuestUser.new
      end
    else
      id = request.env['X-ID-USER']

      return GuestUser.new if id.nil?
    end

    user = User[id]

    if RoleUser.user_have_role? user.id, 'user'
      puts 'Current user should be a AuthUser.'
      AuthUser.new(user.name, user.email, user.image_profile, user.id)
    elsif RoleUser.user_have_role? user.id, 'admin'
      puts 'Current user should be a Admin.'
      Admin.new(user.name, user.email, user.image_profile, user.id)
    end

  end

  def bearer_token
    # Get token from the header
    pattern = /^Bearer /
    header  = request.env['HTTP_AUTHORIZATION']
    header.gsub(pattern, '') if header && header.match(pattern)
  end

  def set_current_user(decode_token)
    # Set current user
    @current_user = current_user decode_token
  end

  def is_admin?
    # Check if current user is admin
    set_current_user.permission_level == 2 || halt(401)
  end

end

class GuestUser
  attr_accessor :expired
  def initialize(params = {})
    @expired = params.fetch(:expired, false)
  end

  def permission_level
    0
  end

  def is_anonimous
    true
  end
  # current_user.admin? returns false. current_user.has_a_baby? returns false.
  # (which is a bit of an assumption I suppose)
  def method_missing(m, *args)
    return false
  end
end

class AuthUser
  attr_reader :id, :username, :email, :picture, :role
  def initialize(name, email, picture, id)
    @username = name
    @email = email
    @picture = picture
    @id = id
    @role = 'user'
  end

  def permission_level
    1
  end

  def is_authenticated
    true
  end
  # current_user.admin? returns false. current_user.has_a_baby? returns false.
  # (which is a bit of an assumption I suppose)
  def method_missing(m, *args)
    return false
  end
end

class Admin
  attr_reader :id, :username, :email, :picture, :role
  def initialize(name, email, picture, id)
    @username = name
    @email = email
    @picture = picture
    @id = id
    @role = 'admin'
  end

  def permission_level
    2
  end

  def in_role? role
    @role.equal? role
  end

  def is_authenticated
    true
  end
  # current_user.admin? returns false. current_user.has_a_baby? returns false.
  # (which is a bit of an assumption I suppose)
  def method_missing(m, *args)
    return false
  end
end