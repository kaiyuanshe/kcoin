module GithubHelpers
  include UserAppHelpers
  include FabricHelpers

  # all supported events: https://developer.github.com/webhooks/#events
  SUPPORTED_EVENTS = %w[pull_request push].freeze
  PROJECT_IMPORT_EVENT = 'project_import'.freeze # special event while importing a new project in kcoin
  WEBHOOK_NAME = 'web'.freeze
  WEBHOOK_EVENTS = ['*'].freeze

  WEBHOOK_EVENT_STATUS_INIT = 0
  WEBHOOK_EVENT_STATUS_PERSISTED = 1 # persisted in block chain

  def event_supported?(event_type)
    SUPPORTED_EVENTS.include? event_type
  end

  def verify_signature(payload_body)
    json = JSON.parse(payload_body)
    project = Project.get_by_github_project_id json['repository']['id'].to_i
    halt 404, 'Project not imported' unless project
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), project.secret, payload_body)
    halt 403, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end

  def on_event_received(params, user_agent, github_delivery, github_event, action)
    payload = params.to_s
    puts 'event payload:' + payload

    sender_login = params[:sender][:login]
    sender_id = params[:sender][:id].to_s
    sender_node_id = params[:sender][:node_id]
    sender_avatar_url = params[:sender][:avatar_url]
    repository_name = params[:repository][:name]
    repository_id = params[:repository][:id]
    repository_node_id = params[:repository][:node_id]
    repository_full_name = params[:repository][:full_name]
    repository_owner_login = params[:repository][:owner][:login]
    repository_owner_id = params[:repository][:owner][:id]
    repository_owner_node_id = params[:repository][:owner][:node_id]

    unless GithubEvent.has_received? github_delivery
      puts "persist event #{github_delivery} of type #{github_event}"
      GithubEvent.insert(github_delivery_id: github_delivery,
                         user_agent: user_agent,
                         github_event: github_event,
                         action: action,
                         sender_login: sender_login,
                         sender_id: sender_id,
                         sender_node_id: sender_node_id,
                         repository_name: repository_name,
                         repository_id: repository_id,
                         repository_node_id: repository_node_id,
                         repository_full_name: repository_full_name,
                         repository_owner_login: repository_owner_login,
                         repository_owner_id: repository_owner_id,
                         repository_owner_node_id: repository_owner_node_id,
                         received_at: Time.now,
                         payload: payload,
                         processing_state: WEBHOOK_EVENT_STATUS_INIT)
    end

    # create oauth if not exists so that user can be credited before registering in kcoin
    user_eth_account = Digest::SHA1.hexdigest(UserAppHelpers::GITHUB + sender_id)
    oauth = Oauth.first(oauth_provider: UserAppHelpers::GITHUB, open_id: sender_id)
    unless oauth
      Oauth.insert(login: sender_login,
                   name: sender_login,
                   oauth_provider: UserAppHelpers::GITHUB,
                   open_id: sender_id,
                   eth_account: user_eth_account,
                   avatar_url: sender_avatar_url,
                   created_at: Time.now,
                   last_login_at: Time.now)
    end

    # trigger block chain transfer
    event = GithubEvent.get_by_delivery_id github_delivery
    project = Project.get_by_github_project_id repository_id
    # TODO: implement rules, using rule engine for example. Get rule by project and event. 5 here for testing purpose
    halt 200, "event #{github_delivery} already processed" if event_processed(event)
    puts "sending transaction to block chain for event #{github_delivery}"
    bc_resp = transfer(project.symbol, project.eth_account, user_eth_account, 5)
    # TODO: support more, pull_request and push only for now
    message = if github_event.eql? 'push'
                '提交代码(Push)'
              else
                '提交代码(Pull Request)'
              end
    KCoinTransaction.insert(
      eth_account_from: project.eth_account,
      eth_account_to: user_eth_account,
      transaction_id: bc_resp['transactionId'],
      transaction_type: github_event,
      message: message,
      correlation_id: event.id,
      correlation_table: 'github_events',
      created_at: Time.now
    )
    event.update(processing_state: WEBHOOK_EVENT_STATUS_PERSISTED,
                 transaction_id: bc_resp['transactionId'],
                 processing_time: Time.now)
    puts "event #{github_delivery} of type #{github_event} successfully persisted in block chain"
  end

  def event_processed(event)
    event.processing_state == WEBHOOK_EVENT_STATUS_PERSISTED
  end

  def github_v3_api(path)
    "https://api.github.com/#{path.sub(/^\//, '')}"
  end

  def authorize_github_v3_api(headers = nil)
    headers ||= {}
    # append auth header
    access_token = current_user.access_token
    headers[:Authorization] = "token #{access_token}"
    headers['User-Agent'] = 'Kaiyuanshe KCoin project'
    headers[:Accept] = 'application/json'
    headers['Content-Type'] = 'application/json'
    headers
  end

  def list_projects(user_id)
    github_account = Oauth.where(user_id: user_id, oauth_provider: GITHUB).first
    unless github_account
      return {
        login: '/auth/github/login?redirect_uri=/project'
      }.to_json
    end

    # TODO: improve the repo list
    repo_path = github_v3_api "users/#{github_account.login}/repos?type=all&page=1&per_page=100?client_id=#{CONFIG[:github][:client_id]}&client_secret=#{CONFIG[:github][:client_secret]}"
    user_projects = HTTParty.get(repo_path)
    halt user_projects.code if user_projects.code / 100 != 2
    user_projects.body
  end

  def state_contributors(owner, project_name)
    # repo_name: org/project or user/project
    uri = github_v3_api "repos/#{owner}/#{project_name}/stats/contributors?client_id=#{CONFIG[:github][:client_id]}&client_secret=#{CONFIG[:github][:client_secret]}"
    resp = HTTParty.get uri
    raise "failed in state contributors of #{owner}/#{project_name}" unless resp.code / 100 == 2
    resp = JSON.parse(resp.body)
    result = resp.map do |item|
      [(item['author'] || {})['login'], item['total']]
    end

    # Hash.new((item['author'] || {})['login'] => item['total'])
    result
  end

  def list_contributors(owner, project_name)
    # repo_name: org/project or user/project
    uri = github_v3_api "repos/#{owner}/#{project_name}/contributors?client_id=#{CONFIG[:github][:client_id]}&client_secret=#{CONFIG[:github][:client_secret]}"
    resp = HTTParty.get uri
    raise "failed in list contributors of #{owner}/#{project_name}" unless resp.code / 100 == 2
    JSON.parse(resp.body)
  end

  # @param [Object] import_context
  def register_webhook(import_context)
    puts "register_webhook: #{import_context}"

    webhook_uri = github_v3_api "/repos/#{import_context[:owner]}/#{import_context[:name]}/hooks"
    options = {
      body: {
        name: WEBHOOK_NAME,
        active: true,
        events: WEBHOOK_EVENTS,
        config: {
          secret: import_context[:secret],
          url: "#{request.scheme}://#{request.host_with_port}/api/github/webhook",
          content_type: 'json'
        }
      }.to_json,
      headers: {
        Accept: 'application/json',
        'Content-Type' => 'application/json'
      }
    }
    authorize_github_v3_api options[:headers]

    resp = HTTParty.post(webhook_uri, options)
    puts "register webhook: #{resp.code}, #{resp.body}"
    raise 'Failed to register webhook' unless (resp.code == 422) || (resp.code / 100 == 2)
    puts 'register webhook end'
    true
  end

  def query_github_project(repo)
    puts "pull repo info #{repo}"
    repo_uri = github_v3_api "/repos/#{repo.sub(/^\//, '')}"
    options = {
      headers: authorize_github_v3_api
    }
    resp = HTTParty.get(repo_uri, options)
    puts "pull repo info #{repo}: #{resp.code}, #{resp.body}"
    raise "Github project #{repo} not found" if resp.code == 404
    resp.body
  end
end
