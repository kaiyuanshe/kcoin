require 'jwt'
require './controllers/base'
require './helpers/website_helpers'
require './helpers/email_helper'
require 'net/smtp'

class UserController < BaseController
  helpers WebsiteHelpers
  helpers EmailAppHelpers

  before do
    set_current_user
    # redirect '/' unless authenticated?
  end

  get '/' do
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
    @user = User.find(email: params[:email])
    if @user
      if @user.password_digest == params[:password]
        session[:user_id] = @user.id
        redirect '/'
      end
    end
  end

  post '/join' do
    user = User.new(login: 'login' + Time.now.to_i.to_s,
                    name: 'name' + Time.now.to_i.to_s,
                    oauth_provider: 'kcoin',
                    open_id: 'open_id' + Time.now.to_i.to_s,
                    password_digest: params[:password],
                    email: params[:email],
                    avatar_url: 'avatar_url' + Time.now.to_i.to_s,
                    creawted_at: Time.now,
                    updateed_at: Time.now,
                    last_login_at: Time.now)

    user.save
    session[:user_id] = user.id
    send_email(user)
    redirect '/'
  end

  get '/validate/email' do
    user = User.first(email: params[:email], oauth_provider: 'kcoin')
    return {flag: false}.to_json if user
    return {flag: true}.to_json
  end

  get '/validate/user' do
    user = User.first(email: params[:email], oauth_provider: 'kcoin', password_digest: params[:password])
    return {flag: true}.to_json if user
    return {flag: false}.to_json
  end
end
