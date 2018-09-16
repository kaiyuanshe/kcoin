require './models/github_event'
require './helpers/github_helpers'

class ApiController < BaseController

  helpers GithubHelpers

  post '/github/webhook' do
    # webhooks doc: https://developer.github.com/webhooks/
    # events and payloads: https://developer.github.com/v3/activity/events/types/

    # verify signature first: https://developer.github.com/webhooks/#delivery-headers
    request.body.rewind
    payload_body = request.body.read
    if CONFIG[:github][:sign_event]
      halt 403, 'access denied. is missing header HTTP_X_HUB_SIGNATURE' unless request.env['HTTP_X_HUB_SIGNATURE']
      verify_signature(payload_body)
    end

    # Read payload of the event from params
    # Read headers of the event from env
    user_agent = env['HTTP_USER_AGENT']
    github_delivery = env['HTTP_X_GITHUB_DELIVERY']
    github_event = env['HTTP_X_GITHUB_EVENT']
    action = params[:action]

    puts "received webhook events #{github_event}, action #{action} from github, delivery: #{github_delivery}, user agent: #{user_agent}"
    unless event_supported? github_event
      puts "event #{github_event} is not supported"
      halt 200
    end

    on_event_received(params, user_agent, github_delivery, github_event, action)

    true
  end
end