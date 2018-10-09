Bundler.require

require './config/init'
require './helpers/website_helpers'
require './helpers/locale_helpers'
require './helpers/fabric_helpers'
require './helpers/user_helpers'
require './helpers/github_helpers'
require './helpers/project_helpers'
require './lib/json_params'
require 'sinatra/reloader'
require 'sinatra-initializers'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'rack/contrib'
require 'rack/protection'

class BaseController < Sinatra::Base
  require './lib/regex_pattern'

  helpers WebsiteHelpers
  helpers LocaleHelpers
  helpers FabricHelpers
  helpers UserAppHelpers
  helpers GithubHelpers
  helpers ProjectHelpers
  helpers Sinatra::ContentFor
  register Sinatra::JsonBodyParams

  use Rack::Locale
  use Rack::Protection

  configure do
    enable :protection # https://stackoverflow.com/questions/10509774/sinatra-and-rack-protection-setting
    enable :sessions
    enable :logging
    enable :dump_errors if development?

    disable :show_exceptions

    # sinatra
    set :template_engine, :haml
    set :haml, :format => :html5
    set :root, Pathname(File.expand_path('../..', __FILE__))
    set :views, 'views'
    set :public_folder, 'public'
    set :static, true
    set :static_cache_control, [:public, max_age: 0]

    # I18n
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.enforce_available_locales = false
    set :default_locale, 'cn'

    # kcoin
    set :kcoin_symbol, 'kcoin-dev'
    set :kcoin_owner, 'kcoin'
  end

  configure :production do
    set :kcoin_symbol, 'kcoin'
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
      unless authenticated? && roles.any? {|role| set_current_user.has_role? role}
        halt 401, {:response => 'Unauthorized access'}
      end
    end
  end

  set(:validate) do |*params_array|
    condition do
      params_array.any? do |k|
        unless params.key?(k)
          # https://stackoverflow.com/questions/3050518/what-http-status-response-code-should-i-use-if-the-request-is-missing-a-required
          halt 422, {:response => 'Any parameter are empty or null'}.to_json
        end
      end
      true # Return true
    end
  end

  set(:only_owner) do |model|
    condition do
      @model = model[params[:id]] or halt 404
      unless @model.id == session[:user_id]
        halt 401, {:response => 'Unauthorized access'}
      end
    end
  end

end
