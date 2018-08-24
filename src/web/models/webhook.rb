class Webhook < Sequel::Model(:webhooks)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer
  def self.webhook_have_received?(github_delivery_id)
    # Search role, if no exist return false
    Webhook.first(:github_delivery_id => github_delivery_id).kind_of?(Webhook)? true : false
  end
end