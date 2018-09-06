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

    on_event_received(params, user_agent, github_delivery, github_event, action)

    true
  end
end