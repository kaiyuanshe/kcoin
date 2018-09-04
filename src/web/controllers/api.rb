require './models/github_event'
require './helpers/github_helper'

class ApiController < BaseController

  helpers GithubHelpers

  post '/github/webhook' do
    # webhooks doc: https://developer.github.com/webhooks/
    # events and payloads: https://developer.github.com/v3/activity/events/types/

    # Read payload of the event from params
    # Read headers of the event from env
    user_agent = env['HTTP_USER_AGENT']
    github_delivery = env['HTTP_X_GITHUB_DELIVERY']
    github_event = env['HTTP_X_GITHUB_EVENT']
    action = params[:action]

    puts "received webhook events #{github_event}, action #{action} from github, delivery: #{github_delivery}, user agent: #{user_agent}"
    unless event_supported? github_event
      halt 200
    end


    payload = params.to_s
    puts 'payload:' + payload

    sender_login = params[:sender][:login]
    sender_id = params[:sender][:id]
    sender_node_id = params[:sender][:node_id]
    repository_name = params[:repository][:name]
    repository_id = params[:repository][:id]
    repository_node_id = params[:repository][:node_id]
    repository_full_name = params[:repository][:full_name]
    repository_owner_login = params[:repository][:owner][:login]
    repository_owner_id = params[:repository][:owner][:id]
    repository_owner_node_id = params[:repository][:owner][:node_id]

    unless webhook_event_have_received? github_delivery
      webhook = GithubEvent.new(github_delivery_id: github_delivery,
                            user_agent: user_agent,
                            github_event: github_event,
                            action: action,
                            sender_login: sender_login,
                            sender_id: sender_id,
                            sender_node_id: sender_node_id,
                            repository_name: repository_name,
                            repository_id: repository_id,
                            repository_node_id: repository_node_id,
                            repository_full_name: repository_full_name,
                            repository_owner_login: repository_owner_login,
                            repository_owner_id: repository_owner_id,
                            repository_owner_node_id: repository_owner_node_id,
                            received_at: Time.now,
                            payload: payload,
                            processing_state: 0)
      webhook.save
    end

    true
  end
end