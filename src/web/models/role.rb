class Role < Sequel::Model(:roles)
  plugin :timestamps
  plugin :validation_helpers

  def self.role_exist?(name)
    # Search role, if no exist return false
    first(:name => name).kind_of?(Role) ? true : false
  end

  def self.find_role_or_create(name)
    # Search role and return Dataset, if no exist create role and return Dataset
    find_or_create(:name => name)
  end

  def self.add_role_to_user(user_id, role)
    # Add role to user, create raise !
    User[user_id].add_role(find_role_or_create(role))
  end

  def self.remove_role_from_user(user_id, role)
    User[user_id].remove_role(find_role_or_create(role))
  end

  def validate
    super
    validates_presence [:name]
  end

  many_to_many :users

end