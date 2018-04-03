require './routes/base'
require './helpers/website_helpers'

class WebsiteController < BaseController

  helpers WebsiteHelpers

  get '/' do
    haml :index
  end

  get '/dashboard' do
    haml :dashboard, :layout => :base_menu
  end

  get '/explorer' do
    haml :explorer, :layout => :base_menu
  end
end