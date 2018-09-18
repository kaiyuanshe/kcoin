require './controllers/base'
require './helpers/website_helpers'

class ProjectController < BaseController
  helpers WebsiteHelpers

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
    haml :project
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
    github_account = Oauth.where(user_id: current_user.id, oauth_provider: 'github').first
    user_projects = HTTParty.get("https://api.github.com/users/#{github_account.login}/repos?type=all&page=1&per_page=100")
    user_projects.body
  end

  post '/saveProject' do
    name = params[:name]
    first_word = Spinying.parse(word: name)[0].upcase
    tmpfile = params[:images]
    project_id = params[:project_id].to_s

    count = User[current_user.id].projects_dataset.where(project_code: project_id).count

    return {code: 602, msg: '您已经导入了该项目，请重新选择'}.to_json if count > 0

    if tmpfile
      img = 'data:' + tmpfile[:type] + ';base64,' + Sequel.blob(Base64.encode64(File.read(tmpfile[:tempfile])))
    end
    project = Project.create(name: name.to_s,
                             created_at: Time.now,
                             owner: params[:owner],
                             img: img,
                             first_word: first_word,
                             project_code: project_id)
    result = User[current_user.id].add_project(project)
    {code: 601, msg: '您已经导入了该项目，请重新选择'}.to_json
  end

  post '/updateProject' do
    project = User[current_user.id].projects_dataset.where(project_code: params[:project_code]).first
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
    project_code = params[:project_code]
    @project = User[current_user.id].projects_dataset.where(project_code: project_code).first

    # fetch data from chaincode
    # amount = HTTParty.post('http://localhost:8080/kcoin/fabric/proxy',
    #                     {
    #                         headers: {:Accept => 'application/json', 'Content-Type' => 'text/json'},
    #                         body: {fn: 'balance', args: ['symbol', 'owner']}.to_json
    #                     })
    # @kcoin = JSON.parse(amount.body)
    @kcoin = JSON.parse('{"payload": 300}')

    # fetch member data form github
    @collaborators = JSON.parse(HTTParty.get("https://api.github.com/repos/#{@project.owner}/#{@project.name}/contributors").body)
    haml :project_detail, layout: false
  end


  get '/getProjectState' do
    state = HTTParty.get("https://api.github.com/repos/#{params[:repo_owner]}/#{params[:repo_name]}/stats/contributors").body
    state
  end

end
