module GithubHelpers

  # all supported events: https://developer.github.com/webhooks/#events
  SupportedEvents = %w(fork milestone pull_request push watch)

  def event_supported?(event_type)
    SupportedEvents.include? event_type
  end

  def webhook_event_have_received?(github_delivery_id)
    # Search role, if no exist return false
    GithubEvent.first(:github_delivery_id => github_delivery_id).kind_of?(GithubEvent)? true : false
  end
end