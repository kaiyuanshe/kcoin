migration 'create the user email table' do
  database.create_table :user_emails do
    primary_key :id
    foreign_key :user_id, :users
    String :email, :null => false
    index :email, :unique => true
    Boolean :verified, :null => true
    Timestamp :created_at, null: false
  end
end
