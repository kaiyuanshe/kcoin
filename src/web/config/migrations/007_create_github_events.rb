migration 'create the github webhook events table' do
  database.create_table :github_events do
    primary_key :id
    String :github_delivery_id, :null => false
    index :github_delivery_id, :unique => true
    String :user_agent, :null => true
    String :github_event
    String :action, :null => true
    String :sender_login
    String :sender_id
    String :sender_node_id, :null => true
    String :repository_name
    String :repository_id
    String :repository_node_id, :null => true
    String :repository_full_name, :null => true
    String :repository_owner_login, :null => true
    String :repository_owner_id, :null => true
    String :repository_owner_node_id, :null => true
    Timestamp :received_at
    String :payload
    Integer :processing_state
    String :transaction_id, :null => true
    Timestamp :processing_time, :null => true
  end
end