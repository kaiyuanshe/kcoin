require './controllers/base'

class WebsiteController < BaseController

  get '/' do
    # haml :index, :layout => false
    redirect '/project'
  end

  get '/explorer' do
    haml :explorer
  end

  get '/locale/:locale' do
    session[:locale] = params[:locale]
    redirect request.referrer
  end

  get '/initkcoin', :role => [:admin] do
    symbol = settings.kcoin_symbol
    owner = settings.kcoin_owner
    kcoin_balance = query_balance(symbol, owner)
    if kcoin_balance ==0
      puts "init KCoin in hyperLedger"
      kcoin_context = {
        :symbol => symbol,
        :token_name => symbol,
        :eth_account => owner,
        :init_supply => 10000000
      }
      init_ledger kcoin_context
    end
    'OK'
  end
end