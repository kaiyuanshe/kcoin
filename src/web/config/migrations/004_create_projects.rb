migration 'create the projects table' do
  database.create_table :projects do
    primary_key :id
    String :name, :null => false
    String :description, :null => false
    String :source, :null => false
    String :website, :null => false
    String :contract_name, :null => false
    String :contract_symbol, :null => false
    String :contract_address, :null => false
    String :contract_abi, :null => false
    Timestamp :created_at, :null => false
  end
end