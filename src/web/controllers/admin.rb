require './controllers/base'

class AdminController < BaseController

  before do
    set_current_user
    redirect '/auth/login' unless authenticated?
    redirect '/project' unless current_user.is_admin?
  end

  get '/' do
    symbol = settings.kcoin_symbol
    owner = settings.kcoin_owner
    kcoin_balance = query_balance(symbol, owner)
    haml :admin, locals: {
      :kcoin_balance => kcoin_balance
    }
  end

  post '/issue' do
    amount = params[:amount].to_i
    puts "amount to issue: #{amount.to_s}"

    symbol = settings.kcoin_symbol
    owner = settings.kcoin_owner
    kcoin_balance = query_balance(symbol, owner)
    if kcoin_balance ==0
      puts "init KCoin in hyperLedger"
      kcoin_context = {
        :symbol => symbol,
        :token_name => symbol,
        :eth_account => owner,
        :init_supply => amount
      }
      init_ledger kcoin_context
    end

    redirect '/admin'
  end

  post '/invest' do
    amount = params[:amount].to_i
    project_id = params[:project_id].to_i
    puts "invest kcoin of quantity #{amount.to_s} to project #{project_id.to_s}"

    symbol = settings.kcoin_symbol
    owner = settings.kcoin_owner
    kcoin_balance = query_balance(symbol, owner)
    project = Project[project_id]

    if project.nil?
      error_msg = '项目不存在'
    elsif kcoin_balance < amount
      error_msg = '余额不足'
    else
      transfer(symbol, owner, project.eth_account, amount)
      error_msg = ''
    end

    if error_msg.length > 0
      haml :admin, locals: {
        :kcoin_balance => kcoin_balance - amount,
        :error_msg => error_msg
      }
    else
      redirect '/admin'
    end

  end

end