Bundler.require

require './config/init'
require './helpers/user_helper'
require './lib/json_params'
require 'sinatra/reloader'
require 'sinatra-initializers'

class BaseController < Sinatra::Base
  require './lib/regex_pattern'

  helpers Sinatra::ContentFor
  helpers UserAppHelpers
  register Sinatra::JsonBodyParams

  configure do
    enable :protection # https://stackoverflow.com/questions/10509774/sinatra-and-rack-protection-setting
    enable :sessions
    enable :logging
    enable :dump_errors if development?

    disable :show_exceptions

    set :template_engine, :haml
    set :haml, :format => :html5
    set :root,  Pathname(File.expand_path('../..', __FILE__))
    set :views, 'views'
    set :public_folder, 'public'
    set :static, true
    set :static_cache_control, [:public, max_age: 0]
    set :session_secret, '%1qA2wS3eD4rF5tG6yH7uJ8iK9oL$'
  end

  configure :development do
    register Sinatra::Reloader
  end

  before do
    set_current_user
  end

  set(:auth) do |*params_array|
    condition do
      redirect '/' unless authenticated?
    end
  end

  set(:role) do |*roles|
    condition do
      unless authenticated? && roles.any? {|role| set_current_user.in_role? role }
        halt 401, {:response=>'Unauthorized access'}
      end
    end
  end

  set(:validate) do |*params_array|
    condition do
      params_array.any? do |k|
        unless params.key?(k)
          # https://stackoverflow.com/questions/3050518/what-http-status-response-code-should-i-use-if-the-request-is-missing-a-required
          halt 422, {:response=>'Any parameter are empty or null'}.to_json
        end
      end
      true # Return true
    end
  end

  set(:only_owner) do |model|
    condition do
      @model = model[params[:id]] or halt 404
      unless @model.id == session[:user_id]
        halt 401, {:response=>'Unauthorized access'}
      end
    end
  end
end
