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
      bc_resp = init_ledger kcoin_context
      KCoinTransaction.insert(
        eth_account_to: owner,
        transaction_id: bc_resp['transactionId'],
        transaction_type: 'kcoin',
        message: '创建KCoin',
        created_at: Time.now
      )
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
      bc_resp = transfer(symbol, owner, project.eth_account, amount)
      error_msg = ''
      KCoinTransaction.insert(
        eth_account_from: owner,
        eth_account_to: project.eth_account,
        transaction_id: bc_resp['transactionId'],
        transaction_type: 'invest',
        message: '注资KCoin',
        correlation_id: project.id,
        correlation_table: 'projects',
        created_at: Time.now
      )
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