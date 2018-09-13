module ProjectHelpers

  include GithubHelpers

  def project_not_exist? (project_id)
    project = Project.first(:project_id => project_id)
    project.eql? nil
  end

  def import_project(import_context)
    # save project
    if project_not_exist?(import_context[:project_id])
      puts "Persisting project #{import_context[:project_id]} by user"
      project = Project.create(name: import_context[:name],
                               created_at: Time.now,
                               owner: import_context[:owner],
                               img: import_context[:img],
                               secret: SecureRandom.hex,
                               first_word: import_context[:first_word],
                               project_id: import_context[:project_id])
      User[current_user.id].add_project(project)
    end


    project = Project.first(:project_id => import_context[:project_id])
    import_context[:secret] = project.secret
    # register webhook
    register_webhook import_context
    true
  end

end