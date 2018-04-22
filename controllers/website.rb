require './controllers/base'
require './helpers/website_helpers'

class WebsiteController < BaseController

  helpers WebsiteHelpers

  get '/' do
    haml :index
  end

  get '/explorer' do
    haml :explorer, :layout => :base_menu
  end
end