require './controllers/base'

class ExchangeController < BaseController

  get '/' do
    haml :exchange
  end

end