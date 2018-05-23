require 'jwt'
require 'openssl'
require './controllers/base'

class AuthController < BaseController
  helpers WebsiteHelpers

  get '/github/login' do
    github_authorize
    redirect '/user/'
  end

  get '/github/callback' do
    redirect '/user/' if handle_github_callback
    halt 401, 'Unable to Authenticate Via GitHub'
  end

  get '/login' do
    haml :login, layout: false
  end

  get '/join' do
    haml :join, layout: false
  end

  post '/login', :validate => %i(email password) do
    @user = User.first(:email => params[:email])
    if @user
      if @user.authenticate params[:password]
        {:response => 'User Logged successfully',
         :token => JWT.encode({user_id: @user.id}, settings.signing_key, 'RS256', {exp: Time.now.to_i + 60 * 30}),
         :id => @user.id,
         :username => @user.name,
         :email => @user.email,
         :image_profile => @user.image_profile,
        }.to_json
      else
        halt 403, {:response => 'Authentication failed'}.to_json
      end
    else
      halt 404, {:response => 'User no found'}.to_json
    end
  end

  get '/logout' do
    logout!
    redirect back
  end

end