require 'jwt'
require './controllers/base'
require './helpers/website_helpers'
require 'net/smtp'

class UserController < BaseController
  helpers WebsiteHelpers

  before do
    set_current_user
    # redirect '/' unless authenticated?
  end

  get '/' do
    haml :user
  end

  post '/address' do
    save_address params[:address]
    redirect '/user'
  end

  get '/login' do
    haml :login, layout: false
  end

  get '/join' do
    haml :join, layout: false
  end

  post '/login' do
    @user = User.find(email: params[:email])
    if @user
      if @user.password_digest == params[:password]
        session[:user_id] = @user.id
        redirect '/'
      else
        halt 403, { response: 'password is invalid' }.to_json
      end
    end
  end

  post '/join' do
    user = User.new(login: 'login' + Time.now.to_i.to_s,
                    name: 'name' + Time.now.to_i.to_s,
                    oauth_provider: 'oauth' + Time.now.to_i.to_s,
                    open_id: 'open_id' + Time.now.to_i.to_s,
                    password_digest: params[:password],
                    email: params[:email],
                    avatar_url: 'avatar_url' + Time.now.to_i.to_s,
                    creawted_at: Time.now,
                    updateed_at: Time.now,
                    last_login_at: Time.now)

    send_email(user.email)
    user.save
    redirect '/user/login'
  end

  def send_email(_email)
    require 'net/smtp'

    message = <<MESSAGE_END
From: 13993143738@163.com
To: 1054602234@qq.com
Subject: kcoin 帐号激活

尊敬的用户:

您在 kcoin 上注册了一个新用户，
请点下面链接以激活您的账号：
xxx


MESSAGE_END

    Net::SMTP.start('smtp.163.com',
                    25,
                    '163.com',
                    '13993143738', 'a19924141', :plain) do |smtp|
      smtp.send_message message, '13993143738@163.com',
                        '1054602234@qq.com'
    end
  end
end
