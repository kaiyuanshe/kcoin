require 'jwt'
require 'openssl'
require './controllers/base'

class AuthController < BaseController

  get '/github/login' do
    redirect_uri = request.params['redirect_uri'].to_s
    if redirect_uri.eql? ''
      github_authorize(redirect_uri)
      redirect '/project/'
    else
      github_authorize('?callback_uri=' + redirect_uri)
      redirect redirect_uri
    end
  end

  get '/github/callback' do
    redirect_uri = request.params['callback_uri'].to_s
    begin
      redirect redirect_uri if handle_github_callback
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

end