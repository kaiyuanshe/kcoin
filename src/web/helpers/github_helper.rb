module GithubHelpers

  # all supported events: https://developer.github.com/webhooks/#events
  SUPPORTED_EVENTS = %w(fork milestone pull_request push watch)

  def event_supported?(event_type)
    SUPPORTED_EVENTS.include? event_type
  end

  def on_event_received(params, user_agent, github_delivery, github_event, action)
    payload = params.to_s
    puts 'event payload:' + payload

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
      puts "persist event #{github_delivery} of type #{github_event}"
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

    # create oauth if not exists
  end

  def webhook_event_have_received?(github_delivery_id)
    # Search role, if no exist return false
    GithubEvent.first(:github_delivery_id => github_delivery_id).kind_of?(GithubEvent)? true : false
  end
end