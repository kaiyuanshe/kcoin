migration 'create the roles table' do
  database.create_table :roles do
    primary_key :id
    String :name, :unique => true
    Timestamp :created_at, null: false
    Timestamp :updated_at
  end
end