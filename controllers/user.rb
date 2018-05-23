require './controllers/base'
require './helpers/website_helpers'

class UserController < BaseController
  helpers WebsiteHelpers

  before do
    set_current_user
    redirect '/' unless authenticated?
  end

  get '/' do
    haml :user
  end

  post '/address' do
    save_address params[:address]
    redirect '/user'
  end
end
