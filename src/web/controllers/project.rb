require './controllers/base'
require 'thread'

class ProjectController < BaseController
  helpers HistoryHelpers

  before do
    enforce_login '/project'
  end

  get '/' do
    haml :project
  end

  get '/import' do
    haml :import
  end

  get '/search_github' do
    begin
      query_github_project params[:repo].strip
    rescue Exception => ex
      {
        error: {
          code: 404,
          message: ex.message
        }
      }.to_json
    end
  end

  get '/projectLists' do
    projects = list_user_project(current_user.id, settings.kcoin_symbol)
    projects.to_json
  end

  get '/fetchList' do
    list_projects current_user.id
  end

  post '/saveProject' do
    # fetch data from request params
    import_context = {
      user_id: current_user.id,
      name: params[:name],
      first_word: Spinying.parse(word: params[:name])[0].upcase,
      tmpfile: params[:images],
      github_project_id: params[:github_project_id].to_s,
      owner: params[:owner],
      custom_name: params[:custom_name],
      token_name: params[:token_name],
      init_supply: params[:init_supply],
      discuss_method: params[:discuss_method],
      contributors: JSON.parse(params[:contributors])
    }

    # encode img to base64
    if import_context[:tmpfile]
      f = import_context[:tmpfile]
      img_type = f[:type]
      image_content = Sequel.blob(Base64.encode64(File.read(f[:tempfile])))
      import_context[:img] = "data:#{img_type};base64,#{image_content}"
    end

    begin
      import_project import_context
      { code: 601, msg: t('project_import_dup') }.to_json
    rescue Exception => e
      puts e.to_s
      { code: 602, msg: "#{t('project_import_fail')}#{e.message}" }.to_json
    end
  end

  post '/updateProject' do
    project = User[current_user.id].projects_dataset.where(github_project_id: params[:github_project_id]).first
    tmpfile = params[:images]
    if tmpfile
      img = 'data:' + tmpfile[:type] + ';base64,' + Sequel.blob(Base64.encode64(File.read(tmpfile[:tempfile])))
    end
    project.update(custom_name: params[:custom_name], img: img)
    { code: 601, msg: '项目信息修改完成' }.to_json
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
    token_history = nil
    kcoin_history = nil
    collaborators = nil

    # fetch project message
    github_project_id = params[:github_project_id]
    project = Project.get_by_github_project_id(github_project_id)
    halt 404, t('project_not_exist') unless project

    # fetch member data form github
    t1 = Thread.new do
      puts 'start fetch data from gitHub'
      Mutex.new.synchronize do
        collaborators = list_contributors(project.owner, project.name)
      end
      puts 'end fetch data from gitHub'
    end

    # fetch data from chaincode
    t2 = Thread.new do
      puts 'start fetch data from chainCode'
      token_history = get_history_by_project(project.symbol, project.eth_account)
      kcoin_history = get_kcoin_history(project.eth_account)
      kcoin_history[:uId] = current_user.id
      token_history[:pId] = project.id
      puts 'end fetch data from chainCode'
    end

    t1.join
    t2.join

    haml :project_detail, layout: false, locals: { token_history: token_history,
                                                   kcoin_history: kcoin_history,
                                                   collaborators: collaborators,
                                                   project: project }
  end

  get '/getProjectState' do
    state = state_contributors(params[:repo_owner], params[:repo_name])
    state.to_json
  end

  get '/history' do
    history = if params[:pId].nil?
                get_kcoin_history((User[params[:uId]] || {})[:eth_account])
              else
                project = Project[params[:pId]]
                get_history_by_project(project[:symbol], project[:eth_account])
              end
    haml :history, locals: { history: history }
  end

  get '/back' do
    redirect back
  end
end
