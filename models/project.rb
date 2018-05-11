class Project < Sequel::Model(:projects)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence [:name]
  end

  many_to_many :users
end