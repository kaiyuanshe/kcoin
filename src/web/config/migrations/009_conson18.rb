migration 'create the table for coscon 2018 poll' do
  database.create_table :coscon_poll_2018 do
    primary_key :id
    String :email, :unique => true, null: false
    Boolean :kcoin_issued
    Timestamp :created_at, null: false
    Timestamp :issued_at, null: true
  end

end