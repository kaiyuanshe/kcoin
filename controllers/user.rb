require './controllers/base'
require './helpers/website_helpers'

class UserController < BaseController

  helpers WebsiteHelpers

  before do
    set_current_user
    redirect '/' unless authenticated?
  end

  get '/' do
    haml :user, :layout => :base_menu
  end

end