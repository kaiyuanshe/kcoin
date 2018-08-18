migration 'create the projects table' do
  database.create_table :projects do
    primary_key :id
    String :project_code, :null => false
    String :name, :null => false
    String :owner, :null => false
    String :first_word, :null => false
    String :description, :null => true
    File :img, :null=>true
    String :source, :null => true
    String :website, :null => true
    String :contract_name, :null => true
    String :contract_symbol, :null => true
    String :contract_address, :null => true
    String :contract_abi, :null => true
    Timestamp :created_at, :null => false
  end
end