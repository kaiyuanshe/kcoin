migration 'create the users table' do
  database.create_table :users do
    primary_key :id
    String :login
    String :name, :null => true
    String :oauth_provider, :null => false
    String :open_id, :null => true
    String :password_digest, :null => true
    String :email, :null => false
    String :avatar_url, :null => true
    Timestamp :created_at, null: false
    Timestamp :updated_at, :null => true
    Timestamp :last_login_at, :null => true
    String :eth_account, :null => true
  end
end