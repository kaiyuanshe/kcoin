migration 'add custom_name,token_name,init_supply,discuss_method to projects table' do
  database.add_column :projects, :custom_name, String
  database.add_column :projects, :token_name, String
  database.add_column :projects, :init_supply, String
  database.add_column :projects, :discuss_method, String
end