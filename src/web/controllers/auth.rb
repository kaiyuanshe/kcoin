require 'jwt'
require 'openssl'
require './controllers/base'

# controller for login/logout, for anonymous user
class AuthController < BaseController
  def auth_redirect_uri
    params['redirect_uri'] ||= params[:redirect_uri] ||= session[:redirect_uri] ||= '/'
  end

  get '/github/login' do
    github_authorize(auth_redirect_uri)
  end

  get '/github/callback' do
    begin
      redirect auth_redirect_uri if handle_github_callback
    rescue Exception => ex
      puts ex.to_s
      halt 409, ex.message
    end

    halt 401, 'Unable to Authenticate Via GitHub'
  end

  get '/logout' do
    logout!
    redirect back
  end

  get '/login' do
    session[:redirect_uri] = request.params['redirect_uri'] ||= '/'
    haml :login, layout: false
  end

  post '/login' do
    email = params[:email].to_s
    pwd = Digest::SHA1.hexdigest(params[:password])
    if kcoin_user_login(email, pwd)
      redirect session[:redirect_uri] ||= '/'
    else
      redirect 'auth/login'
    end
  end

  get '/join' do
    session[:redirect_uri] = request.params['redirect_uri'] ||= '/'
    haml :join, layout: false
  end

  # Registered user
  post '/join' do
    login_value = params[:login]
    login_value = params[:email].split('@')[0] if login_value.empty?

    DB.transaction do
      exist = User.first(email: params[:email])
      if exist.nil?
        user = User.new(login: login_value,
                        name: params[:name],
                        password_digest: Digest::SHA1.hexdigest(params[:password]),
                        eth_account: Digest::SHA1.hexdigest(params[:email]),
                        email: params[:email],
                        avatar_url: nil,
                        activated: true,
                        created_at: Time.now,
                        updated_at: Time.now,
                        last_login_at: Time.now)

        user.save
        if UserEmail.first(email: params[:email]).nil?
          UserEmail.insert(user_id: user.id,
                           email: params[:email],
                           verified: false,
                           verification_code: SecureRandom.urlsafe_base64(32).to_s,
                           created_at: Time.now)
        end
        session[:user_id] = user.id
      elsif exist.password_digest.nil?
        exist.update(
          login: login_value,
          name: params[:name],
          password_digest: Digest::SHA1.hexdigest(params[:password])
        )
        session[:user_id] = exist.id
      end
    end

    user = User[session[:user_id]]

    # send regist mail
    send_register_email(user)

    redirect auth_redirect_uri
  end

  # Email verification
  get '/join/verification/:token' do
    token = params['token']
    if token =~ /^[\w\-]+$/
      DB.transaction do
        user_email = UserEmail.first(verification_code: token)
        if !user_email.nil?
          user_email.update(verified: true, verification_code: nil)
          'Your email has been verified'
        else
          'Invalid verification code'
        end
      end
    else
      'Invalid verification code'
    end
  end

  # Verify email is registered
  post '/validate/email' do
    valid = email_not_registered params[:email]
    {
      flag: valid
    }.to_json
  end

  # Verify user is existed
  post '/validate/user' do
    param = params[:email].to_s
    pwd = Digest::SHA1.hexdigest(params[:password])
    user = if param.include? '@'
             User.first(email: param, password_digest: pwd)
           else
             User.first(login: param, password_digest: pwd)
    end
    user ? { flag: true }.to_json : { flag: false }.to_json
  end
end
