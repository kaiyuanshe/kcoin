require 'jwt'
require './controllers/base'
require './helpers/website_helpers'
require './helpers/email_helper'
require 'net/smtp'

class UserController < BaseController
  helpers WebsiteHelpers
  helpers EmailAppHelpers
  KCOIN = 'kcoin'

  before do
    set_current_user
  end

  get '/' do
    redirect '/' unless authenticated?
    haml :user
  end

  post '/address' do
    save_address params[:address]
    redirect '/user'
  end

  get '/login' do
    haml :login, layout: false
  end

  get '/join' do
    haml :join, layout: false
  end

  post '/login' do
    param = params[:email].to_s
    @user = nil
    if param.include? '@'
      @user = User.first(email: param, oauth_provider: KCOIN, password_digest: params[:password])
    else
      @user = User.first(login: param, oauth_provider: KCOIN, password_digest: params[:password])
    end
    if @user
      if @user.password_digest == params[:password]
        session[:user_id] = @user.id
        redirect '/'
      end
    end
  end

  # Registered user
  post '/join' do
    login_value = nil
    if params[:login].eql? ''
      login_value = params[:email].split('@')[0]
    end
    user = User.new(login: login_value,
                    name: params[:name],
                    oauth_provider: KCOIN,
                    open_id: nil,
                    password_digest: params[:password],
                    email: params[:email],
                    avatar_url: nil,
                    creawted_at: Time.now,
                    updateed_at: Time.now,
                    last_login_at: Time.now)

    user.save
    session[:user_id] = user.id
    send_email(user)
    redirect '/'
  end

  # Verify email is registered
  get '/validate/email' do
    user = User.first(email: params[:email], oauth_provider: KCOIN)
    return user ? {flag: false}.to_json : {flag: true}.to_json
  end


  # Verify user is existed
  get '/validate/user' do
    param = params[:email].to_s
    user = nil
    if param.include? '@'
      user = User.first(email: param, oauth_provider: KCOIN, password_digest: params[:password])
    else
      user = User.first(login: param, oauth_provider: KCOIN, password_digest: params[:password])
    end
    return user ? {flag: true}.to_json : {flag: false}.to_json
  end
end
