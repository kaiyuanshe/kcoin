require 'jwt'
require './controllers/base'
require './helpers/website_helpers'
require './helpers/email_helper'
require 'net/smtp'
require 'digest/sha1'

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
    if param.include? '@'
      @user = User.first(email: param, password_digest: pwd)
    else
      @user = User.first(login: param, password_digest: pwd)
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
    send_email(user)
    redirect '/'
  end

  # Verify email is registered
  post '/validate/email' do
    user = User.first(email: params[:email])
    user ? {flag: false}.to_json : {flag: true}.to_json
  end


  # Verify user is existed
  post '/validate/user' do
    param = params[:email].to_s
    user = nil
    pwd = Digest::SHA1.hexdigest(params[:password])
    if param.include? '@'
      user = User.first(email: param, password_digest: pwd)
    else
      user = User.first(login: param, password_digest: pwd)
    end
    user ? {flag: true}.to_json : {flag: false}.to_json
  end
end
