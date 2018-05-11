migration 'create the user projects table' do
  database.create_table :user_projects do
    primary_key :id
    foreign_key :project_id, :projects
    foreign_key :user_id, :users
    String :role, :null => false
    String :website, :null => false
    Timestamp :created_at, :null => false
  end
end