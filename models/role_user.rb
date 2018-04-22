class RoleUser < Sequel::Model(:roles_users)

  def self.user_have_role?(user_id, role_id)
    # Check is user have role using the role id or the role name
    if role_id.kind_of? String
      role_id = Role.first(:name=>role_id).id
    end
    first(:user_id=>user_id, :role_id=>role_id).kind_of?(RoleUser) ? true : false
  end

end