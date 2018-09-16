migration 'create the oauth table' do
  database.create_table :oauth do
    primary_key :id
    foreign_key :user_id, :users
    String :login
    String :name, :null => true
    String :oauth_provider, :null => false
    String :open_id, :null => false
    index [:oauth_provider, :open_id], :unique => true
    String :eth_account, :null => false # address of user, especially for un-registered user
    String :email, :null => true
    String :avatar_url, :null => true
    Timestamp :created_at, null: false
    Timestamp :updated_at, :null => true
    Timestamp :last_login_at, :null => true
  end
end
