migration 'create the webhooks table' do
  database.create_table :webhooks do
    primary_key :id
    String :github_delivery_id, :unique => true
    String :user_agent
    String :github_event
    String :sender_login
    String :sender_id
    String :sender_node_id
    String :repository_name
    String :repository_id
    String :repository_node_id
    String :repository_full_name
    String :repository_owner_login
    String :repository_owner_id
    String :repository_owner_node_id
    Timestamp :received_at
    String :full_detail
    Integer :processing_state
    Timestamp :processing_time, :null => true
  end
end