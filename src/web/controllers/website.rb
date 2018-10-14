require './controllers/base'

class WebsiteController < BaseController

  get '/' do
    # haml :index, :layout => false
    redirect '/project'
  end

  get '/locale/:locale' do
    session[:locale] = params[:locale]
    redirect request.referrer
  end

  get '/coscon2018' do
    poll = false
    token_issued = false
    if current_user.is_authenticated?
      first_record = nil
      User[current_user.id].user_emails.each do |x|
        p = CosconPoll2018.first(email: x.email)
        unless p.nil?
          poll = true
          token_issued = token_issued || p.kcoin_issued
          first_record = p if first_record.nil?
        end
      end

      if poll && !token_issued
        #todo persist transactionId
        symbol = settings.kcoin_symbol
        owner = settings.kcoin_owner
        puts "issue KCoin for user #{current_user.id.to_s} for coscon2018 poll"
        transfer(symbol, owner, current_user.eth_account, 100)
        first_record.update(
          kcoin_issued: true,
          issued_at: Time.now
        )
      end

    end

    haml :coscon2018, locals: {
      :poll => poll
    }
  end

end