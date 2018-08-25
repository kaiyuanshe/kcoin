require './controllers/base'

class WebsiteController < BaseController

  get '/' do
    haml :index, :layout => false
  end

  get '/explorer' do
    haml :explorer
  end

  get '/locale/:locale' do
    session[:locale] = params[:locale]
    redirect request.referrer
  end
end