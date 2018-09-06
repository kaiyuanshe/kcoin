migration 'create the users table' do
  database.create_table :users do
    primary_key :id
    String :login
    String :name, :null => true
    String :password_digest, :null => true
    String :email, :unique => true, :null => true
    String :avatar_url, :null => true
    Boolean :activated
    Timestamp :created_at, null: false
    Timestamp :updated_at, :null => true
    Timestamp :last_login_at, :null => true
    String :eth_account, :null => true
  end
end
