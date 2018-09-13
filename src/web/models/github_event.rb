class GithubEvent < Sequel::Model(:github_events)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def self.has_received?(github_delivery_id)
    # Search role, if no exist return false
    event = GithubEvent.first(:github_delivery_id => github_delivery_id)
    !event.nil?
  end
end