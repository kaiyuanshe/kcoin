migration 'create table user_roles' do
  database.create_table :user_roles do
    primary_key :id
    foreign_key :role_id, :roles
    foreign_key :user_id, :users
  end
end