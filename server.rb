require 'sinatra'

get '/' do
  haml :index, :format => :html5
end

get '/dashboard' do
  haml :dashboard, :layout => :base_menu
end