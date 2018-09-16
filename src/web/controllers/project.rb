require './controllers/base'

class ProjectController < BaseController

  before do
    set_current_user
    # if people login return explorer page, else redirect login page
    auth_params = {
      redirect_uri: request.base_url + '/project'
    }
    redirect_url = '/user/login?' + URI.encode_www_form(auth_params)
    redirect redirect_url unless authenticated?
  end

  get '/' do
    haml :project, layout: false
  end

  get '/import' do
    haml :import
  end

  get '/projectLists' do
    user_id = current_user.id
    dataset = User[user_id].projects
    {
      projectList: dataset
    }.to_json
  end

  get '/fetchList' do
    list_projects current_user.id
  end

  post '/saveProject' do
    import_context={
      :user_id => current_user.id,
      :name => params[:name],
      :first_word => Spinying.parse(word: params[:name])[0].upcase,
      :tmpfile => params[:images],
      :github_project_id => params[:project_id].to_s,
      :owner => params[:owner]
    }

    if import_context[:tmpfile]
      f = import_context[:tmpfile]
      img_type = f[:type]
      image_content = Sequel.blob(Base64.encode64(File.read(f[:tempfile])))
      import_context[:img] = "data:#{img_type};base64,#{image_content}"
    end

    begin
      import_project import_context
      {code: 601, msg: t('project_import_dup')}.to_json
    rescue Exception => e
      {code: 602, msg: "#{t('project_import_fail')}#{e.message}"}.to_json
    end
  end

  post '/updateProject' do
    project = User[current_user.id].projects_dataset.where(project_id: params[:github_project_id]).first
    # project.name = params[:name]
    tmpfile = params[:images]
    if tmpfile
      img = 'data:' + tmpfile[:type] + ';base64,' + Sequel.blob(Base64.encode64(File.read(tmpfile[:tempfile])))
      # project.img = img
    end
    # User[current_user.id].update_project(project)
    project.update(name: params[:name], img: img)
    {code: 601, msg: '项目信息修改完成'}.to_json
  end

  get '/projectListsView' do
    user_id = current_user.id
    count = User[user_id].projects.count

    if count > 0
      haml :project_lists, layout: false
    else
      haml :project_lists_none, layout: false
    end
  end

  post '/projectDetailView' do
    # fetch project message
    github_project_id = params[:github_project_id]
    @project = Project.get_by_github_project_id(github_project_id)
    halt 404, t('project_not_exist') unless @project

    # fetch data from chaincode
    balance = query_balance(@project.symbol, current_user)
    @kcoin = {
      :balance => balance['payload'].to_i
    }

    # fetch member data form github
    @collaborators = list_contributors(@project.owner, @project.name)
    haml :project_detail, layout: false
  end


  get '/getProjectState' do
    state = list_contributors(params[:repo_owner], params[:repo_name])
    state.to_s
  end

end
