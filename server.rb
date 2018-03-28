require 'sinatra'

get '/' do
  haml :index
end

get '/dashboard' do
  haml :dashboard, :layout => :base_menu
end

get '/explorer' do
  haml :explorer, :layout => :base_menu
end