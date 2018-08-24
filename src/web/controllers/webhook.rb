require './models/webhook'
class WebhookController < BaseController

  post '/' do
    puts 'get post from github!'
    #params 包含post中payload的信息
    # header中的信息从env中提取

    @user_agent = env["HTTP_USER_AGENT"]
    @x_github_delivery = env["HTTP_X_GITHUB_DELIVERY"]
    @x_github_event = env["HTTP_X_GITHUB_EVENT"]
    unless params[:action] == nil
      @x_github_event = @x_github_event + '_' + params[:action]
    end

    @full_detail = params

    @sender_login = params[:sender][:login]
    @sender_id = params[:sender][:id]
    @sender_node_id = params[:sender][:node_id]

    @repository_name = params[:repository][:name]
    @repository_id = params[:repository][:id]
    @repository_node_id = params[:repository][:node_id]
    @repository_full_name = params[:repository][:full_name]

    @repository_owner_login = params[:repository][:owner][:login]
    @repository_owner_id = params[:repository][:owner][:id]
    @repository_owner_node_id = params[:repository][:owner][:node_id]

    puts 'user_agent : ' + @user_agent.to_s
    puts 'x_github_delivery : ' + @x_github_delivery.to_s
    puts 'x_github_event : ' + @x_github_event.to_s
    puts 'sender_login : ' + @sender_login.to_s
    puts 'sender_id : ' + @sender_id.to_s
    puts 'sender_node_id : ' + @sender_node_id.to_s
    puts 'repository_name : ' + @repository_name.to_s
    puts 'repository_id : ' + @repository_id.to_s
    puts 'repository_node_id : ' + @repository_node_id.to_s
    puts 'repository_full_name : ' + @repository_full_name.to_s
    puts 'repository_owner_login : ' + @repository_owner_login.to_s
    puts 'repository_owner_id : ' + @repository_owner_id.to_s
    puts 'repository_owner_node_id : ' + @repository_owner_node_id.to_s

    unless Webhook.webhook_have_received? @x_github_delivery.to_s
      webhook = Webhook.new(github_delivery_id: @x_github_delivery.to_s,
                            user_agent: @user_agent.to_s,
                            github_event: @x_github_event.to_s,
                            sender_login: @sender_login.to_s,
                            sender_id: @sender_id.to_s,
                            sender_node_id: @sender_node_id.to_s,
                            repository_name: @repository_name.to_s,
                            repository_id: @repository_id.to_s,
                            repository_node_id: @repository_node_id.to_s,
                            repository_full_name: @repository_full_name.to_s,
                            repository_owner_login: @repository_owner_login.to_s,
                            repository_owner_id: @repository_owner_id.to_s,
                            repository_owner_node_id: @repository_owner_node_id.to_s,
                            received_at: Time.now,
                            full_detail: @full_detail.to_s)
      webhook.save
    end
  end
end