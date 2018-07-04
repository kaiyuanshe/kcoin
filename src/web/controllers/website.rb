require './controllers/base'
require './helpers/website_helpers'

class WebsiteController < BaseController

  helpers WebsiteHelpers

  get '/' do
    haml :index, :layout => false
  end

  get '/explorer' do
    haml :explorer
  end

end