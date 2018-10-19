migration 'create the projects table' do
  database.create_table :projects do
    primary_key :id
    String :github_project_id, :null => false # id from github
    index :github_project_id, :unique => true
    String :name, :null => false
    String :owner, :null => false
    String :first_word, :null => false
    String :description, :null => true
    String :secret, :null => false
    File :img, :null => true
    String :symbol, :null => false # symbol of ledger
    String :eth_account, :null => false # address of project
    Timestamp :created_at, :null => false
    String :custom_name, :null => true
    String :token_name, :null => true
    String :init_supply, :null => true
    String :discuss_method, :null => true
  end
end