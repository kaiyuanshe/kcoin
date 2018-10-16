migration 'create the transactions table' do
  database.create_table :transactions do
    primary_key :id
    String :eth_account_from
    String :eth_account_to
    String :transaction_id, :null => false
    # there might be several participants in a transaction. e.g. transfer
    index :transaction_id, :unique => false
    String :transaction_type
    String :message, :null => false
    # the primary key of related table. e.g. project.id or github_event.id
    # we can find the related detail using correlation_id and correlation_table
    Integer :correlation_id
    String :correlation_table
    Timestamp :created_at
  end
end