require 'jwt'
require './controllers/base'
require './helpers/email_helpers'
require 'digest/sha1'

# controller to manager login user profile, login user only
class UserController < BaseController
  helpers EmailHelpers
  helpers UserAppHelpers
  helpers HistoryHelpers
  KCOIN = 'kcoin'

  before do
    enforce_login '/user'
  end

  # user profile page
  get '/' do
    redirect '/' unless authenticated?
    user_id = params[:user_id] ? params[:user_id] : current_user.id
    user_detail = find_user(user_id)
    # fetch data from chaincode
    token_history = get_kcoin_history(user_detail.eth_account)
    token_history[:UserId] = user_id
    project_history = get_project_list_history(user_id)

    haml :user, locals: {user_detail: user_detail,
                         token_history: token_history,
                         project_list: project_history}
  end

  get '/edit_page' do
    user_detail = find_user(params[:user_id])
    haml :user_edit, locals: {user_detail: user_detail}
  end

  post '/update_user' do
    user = find_user(params[:user_id])
    user.update(name: params[:name], brief: params[:brief])
    redirect '/user'
  end
end
