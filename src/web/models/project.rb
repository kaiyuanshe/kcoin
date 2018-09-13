class Project < Sequel::Model(:projects)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence [:name]
  end

  def self.get_by_project_id(project_id)
    Project.first(:project_id => project_id)
  end

  def self.project_not_exist? (project_id)
    project = get_by_project_id project_id
    project.nil?
  end

  many_to_many :users, join_table: :user_projects
end