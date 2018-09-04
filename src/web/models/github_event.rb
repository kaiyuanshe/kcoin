class GithubEvent < Sequel::Model(:github_events)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

end