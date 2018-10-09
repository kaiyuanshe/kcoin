class UserRole < Sequel::Model(:user_roles)

  def self.user_have_role?(user_id, role_id)
    # Check is user have role using the role id or the role name
    if role_id.kind_of? String
      role_id = Role.first(:name => role_id).id
    end
    if role_id.kind_of? Symbol
      role_id = Role.first(:name => role_id.to_s).id
    end
    first(:user_id => user_id, :role_id => role_id).kind_of?(UserRole) ? true : false
  end

end