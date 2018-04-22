class Role < Sequel::Model(:roles)
  plugin :timestamps
  plugin :validation_helpers

  def self.role_exist?(name)
    # Search role, if no exist return false
    first(:name=>name).kind_of?(Role) ? true : false
  end

  def self.find_role_or_create(name)
    # Search role and return Dataset, if no exist create role and return Dataset
    find_or_create(:name=>name)
  end

  def self.add_role_to_user(role, user)
    # Add role to user, create raise !
    user.add_role(role)
  end

  def self.remove_role_from_user(role, user)
    user.remove_role(role)
  end

  def validate
    super
    validates_presence [:name]
    validates_format RegexPattern::Username, :name
  end

  many_to_many :users

end