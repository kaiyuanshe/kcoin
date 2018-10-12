require 'jwt'
require './controllers/base'
require './helpers/email_helpers'
require 'digest/sha1'

class UserController < BaseController
  helpers EmailHelpers
  helpers UserAppHelpers
  helpers HistoryHelpers
  KCOIN = 'kcoin'

  before do
    set_current_user
  end

  # user profile page
  get '/' do
    redirect '/' unless authenticated?
    user_id = params[:user_id] ? params[:user_id] : current_user.id
    user_detail = find_user(user_id)
    # fetch data from chaincode
    history = get_history(user_id)
    project_history = group_history(history)

    haml :user, locals: { user_detail: user_detail,
                          kcoin_history: history,
                          project_list: project_history }
  end

  get '/login' do
    haml :login, layout: false
  end

  get '/join' do
    haml :join, layout: false
  end

  post '/login' do
    param = params[:email].to_s
    pwd = Digest::SHA1.hexdigest(params[:password])
    @user = nil
    @user = if param.include? '@'
              User.first(email: param, password_digest: pwd)
            else
              User.first(login: param, password_digest: pwd)
            end
    if @user
      if @user.password_digest == pwd
        session[:user_id] = @user.id
        redirect '/'
      end
    end
  end

  # Registered user
  post '/join' do
    login_value = params[:login]
    if login_value.empty?
      login_value = params[:email].split('@')[0]
    end

    user = User.new(login: login_value,
                    name: params[:name],
                    password_digest: Digest::SHA1.hexdigest(params[:password]),
                    eth_account: Digest::SHA1.hexdigest(params[:email]),
                    email: params[:email],
                    avatar_url: nil,
                    activated: true,
                    creawted_at: Time.now,
                    updateed_at: Time.now,
                    last_login_at: Time.now)

    user.save
    session[:user_id] = user.id
    send_register_email(user)
    redirect '/'
  end

  # Verify email is registered
  post '/validate/email' do
    user = User.first(email: params[:email])
    user ? { flag: false }.to_json : { flag: true }.to_json
  end


  # Verify user is existed
  post '/validate/user' do
    param = params[:email].to_s
    user = nil
    pwd = Digest::SHA1.hexdigest(params[:password])
    user = if param.include? '@'
             User.first(email: param, password_digest: pwd)
           else
             User.first(login: param, password_digest: pwd)
           end
    user ? { flag: true }.to_json : { flag: false }.to_json
  end

  get '/edit_page' do
    user_detail = find_user(params[:user_id])
    haml :user_edit, locals: { user_detail: user_detail }
  end

  post '/update_user' do
    user = find_user(params[:user_id])
    user.update(name: params[:name], brief: params[:brief])
    redirect '/user'
  end
end
