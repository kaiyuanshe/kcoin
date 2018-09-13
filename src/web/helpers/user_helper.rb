module UserAppHelpers

  KCOIN_LOGIN_INFO = 'kcoin_login_info'
  GITHUB = 'github'
  KCOIN = 'kcoin'

  require 'httparty'
  require 'date'
  require 'net/http'
  require 'uri'

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
                 user[:login],
                 user[:name],
                 user[:email],
                 user[:avatar_url],
                 user[:oauth_provider],
                 user[:eth_account],
                 user[:access_token])
  end

  def set_current_user
    # Set current user
    @current_user = current_user
  end

  def github_authorize(callback_uri)
    return if authenticated?

    session['github_oauth_state'] = SecureRandom.hex
    auth_params = {
      :client_id => CONFIG[:login][:github][:client_id],
      :redirect_uri => request.base_url + '/auth/github/callback' + callback_uri,
      :scope => 'user,admin:repo_hook',
      :state => session['github_oauth_state']
    }
    redirect 'https://github.com/login/oauth/authorize?' + URI.encode_www_form(auth_params)
  end

  def handle_github_callback
    github_state_check = params[:state]
    return false unless github_state_check && github_state_check == session['github_oauth_state']

    github_code = params[:code]
    options = {
      :body => {
        :client_id => CONFIG[:login][:github][:client_id],
        :code => github_code,
        :client_secret => CONFIG[:login][:github][:client_secret]
      },
      :headers => {
        :Accept => 'application/json'
      }
    }
    github_token_url = 'https://github.com/login/oauth/access_token'
    github_response = HTTParty.post(github_token_url, options)

    if github_response.code == 200
      token_details = JSON.parse(github_response.body)
      if token_details.key?('access_token')
        headers = {
          :Accept => 'application/json',
          :Authorization => "token #{token_details['access_token']}",
          'User-Agent' => 'Kaiyuanshe KCoin project'
        }

        user_lookup = HTTParty.get('https://api.github.com/user?', headers: headers)
        email_lookup = HTTParty.get('https://api.github.com/user/emails', headers: headers)

        return set_current_github_user JSON.parse(user_lookup.body),
                                       JSON.parse(email_lookup.body),
                                       token_details['access_token']
      else
        puts "something is wrong, cannot get the access token: #{token_details.to_s}"
        false
      end
    end
    false
  end

  def set_current_github_user(github_user, email_list, auth_token)
    login = github_user['login']
    name = login
    if github_user.key?('name')
      name = github_user['name']
      if name.to_s.empty?
        name = login
      end
    end

    primary = email_list.select {|x| x['primary']}
    email = github_user['email']
    if primary.any?
      email = primary[0]['email']
    end

    user_info = {
      :login => login,
      :name => name,
      :oauth_provider => GITHUB,
      :open_id => github_user['id'],
      :email => email,
      :avatar_url => github_user['avatar_url'],
      :access_token => auth_token
    }

    persist_user user_info
    true
  end

  def binding_user(oauth)
    user = User.first(email: oauth.email)
    if user.eql? nil
      User.insert(login: oauth.login,
                  name: oauth.name,
                  eth_account: oauth.eth_account,
                  email: oauth.email,
                  avatar_url: oauth.avatar_url,
                  activated: true,
                  created_at: Time.now,
                  last_login_at: Time.now)
      user = User.first(email: oauth.email)
      oauth.update(user_id: user.id)
    end
    user
  end

  def persist_user(user_info)
    oauth = Oauth.first(:oauth_provider => user_info[:oauth_provider], :open_id => user_info[:open_id])
    if oauth
      oauth.update(last_login_at: Time.now,
                   login: user_info[:login],
                   name: user_info[:name],
                   email: user_info[:email],
                   avatar_url: user_info[:avatar_url],
                   updated_at: Time.now)
    else
      Oauth.insert(login: user_info[:login],
                   name: user_info[:name],
                   oauth_provider: user_info[:oauth_provider],
                   open_id: user_info[:open_id].to_s,
                   eth_account: Digest::SHA1.hexdigest(user_info[:oauth_provider] + user_info[:open_id].to_s),
                   email: user_info[:email],
                   avatar_url: user_info[:avatar_url],
                   created_at: Time.now,
                   last_login_at: Time.now)
      oauth = Oauth.first(:oauth_provider => user_info[:oauth_provider], :open_id => user_info[:open_id])
    end

    user = binding_user oauth
    user_info[:id] = user.id
    user_info[:eth_account] = user.eth_account
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
  attr_reader :id, :login, :name, :email, :avatar_url, :oauth, :eth_account, :access_token

  def initialize(id, login, name, email, avatar_url, oauth, eth_account, access_token)
    @login = login
    @name = name
    @email = email
    @avatar_url = avatar_url
    @id = id
    @oauth = oauth
    @eth_account = eth_account
    @access_token = access_token
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
