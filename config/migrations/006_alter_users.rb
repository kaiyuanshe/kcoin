migration 'alter users table' do
  alter_table(:users) do
    set_column_allow_null :name
    set_column_allow_null :open_id
    drop_constraint(:email, type: :unique)
  end
end