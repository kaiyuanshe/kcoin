migration 'create join table roles_users' do
  database.create_join_table(
      :role_id=>:roles,
      :user_id=>:users
  )
end