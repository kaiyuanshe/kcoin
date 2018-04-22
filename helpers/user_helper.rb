module UserAppHelpers

  KCOIN_LOGIN_INFO = 'kcoin_login_info'
  GITHUB = 'github'

  require 'httparty'
  require 'date'

  def authenticated?
    set_current_user.is_authenticated?
  end

  def logout!
    session.delete KCOIN_LOGIN_INFO
  end

  def is_admin?
    # Check if current user is admin
    set_current_user.is_admin?
  end

  def current_user
    unless session[KCOIN_LOGIN_INFO]
      return GuestUser.new
    end

    user = session[KCOIN_LOGIN_INFO]
    AuthUser.new(user[:id],
                 user[:name],
                 user[:name],
                 user[:email],
                 user[:avatar_url],
                 user[:oauth_provider])
  end

  def set_current_user
    # Set current user
    @current_user = current_user
  end

  def github_authorize
    return if authenticated?

    session['github_oauth_state'] = SecureRandom.hex
    auth_params = {
        :client_id => CONFIG[:login][:github][:client_id],
        :redirect_uri => request.base_url + '/auth/github/callback',
        :scope => 'user',
        :state => session['github_oauth_state']
    }
    redirect 'https://github.com/login/oauth/authorize?' + URI.encode_www_form(auth_params)
  end

  def handle_github_callback
    github_state_check = params[:state]
    return false unless github_state_check && github_state_check == session['github_oauth_state']

    github_code = params[:code]
    github_response = HTTParty.post('https://github.com/login/oauth/access_token',
                                    :body => {
                                        :client_id => CONFIG[:login][:github][:client_id],
                                        :code => github_code,
                                        :client_secret => CONFIG[:login][:github][:client_secret]
                                    },
                                    :headers => {
                                        :Accept => 'application/json'
                                    })

    if github_response.code == 200
      token_details = JSON.parse(github_response.body)
      if token_details.key?('access_token')
        user_lookup = HTTParty.get('https://api.github.com/user?',
                                   headers: {
                                       :Accept => 'application/json',
                                       :Authorization => "token #{token_details['access_token']}",
                                       'User-Agent' => 'Kaiyuanshe KCoin project'
                                   })
        return set_current_github_user JSON.parse(user_lookup.body), token_details['access_token']
      end
    end
    false
  end

  def set_current_github_user(github_user, auth_token)
    user_info = {
        :login => github_user['login'],
        :name => github_user['name'],
        :oauth_provider => GITHUB,
        :open_id => github_user['id'],
        :email => github_user['email'],
        :avatar_url => github_user['avatar_url']
    }

    persist_user user_info
    true
  end

  def persist_user(user_info)
    user = User.first(:oauth_provider => user_info[:oauth_provider], :open_id => user_info[:open_id])
    if user
      user.update(last_login_at: Time.now,
                  login: user_info[:login],
                  email: user_info[:email],
                  avatar_url: user_info[:avatar_url],
                  updated_at: Time.now)
    else
      User.insert(login: user_info[:login],
                  name: user_info[:name],
                  oauth_provider: user_info[:oauth_provider],
                  open_id: user_info[:open_id],
                  email: user_info[:email],
                  avatar_url: user_info[:avatar_url],
                  created_at: Time.now,
                  last_login_at: Time.now)
      user = User.first(:oauth_provider => user_info[:oauth_provider], :open_id => user_info[:open_id])
      user_info[:id] = user.id
    end

    session[KCOIN_LOGIN_INFO] = user_info
  end

end

class GuestUser
  attr_accessor :expired
  def initialize(params = {})
    @expired = params.fetch(:expired, false)
  end

  def is_anonymous
    true
  end
  # current_user.admin? returns false. current_user.has_a_baby? returns false.
  # (which is a bit of an assumption I suppose)
  def method_missing(m, *args)
    false
  end
end

class AuthUser
  attr_reader :id, :login, :name, :email, :avatar_url, :oauth
  def initialize(id, login, name, email, avatar_url, oauth)
    @login = login
    @name = name
    @email = email
    @avatar_url = avatar_url
    @id = id
    @oauth = oauth
  end

  def is_authenticated?
    true
  end

  def has_role(role)
    RoleUser.user_have_role?(@id, role)
  end

  def is_admin?
    has_role? "admin"
  end

  # current_user.admin? returns false. current_user.has_a_baby? returns false.
  # (which is a bit of an assumption I suppose)
  def method_missing(m, *args)
    return false
  end
end
