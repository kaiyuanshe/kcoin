require './controllers/base'
require './helpers/website_helpers'

class ProjectController < BaseController

  helpers WebsiteHelpers

  get '/' do
    haml :explorer
  end

  get '/import', :auth => nil do
    haml :import
  end

end