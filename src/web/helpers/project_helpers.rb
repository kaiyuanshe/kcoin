module ProjectHelpers
  include EmailHelpers
  include GithubHelpers
  include FabricHelpers

  def import_project(import_context)
    # save project
    persist_project import_context

    project = Project.get_by_github_project_id(import_context[:github_project_id])
    import_context[:id] = project.id
    import_context[:secret] = project.secret
    import_context[:symbol] = project.symbol
    import_context[:eth_account] = project.eth_account
    import_context[:init_supply] = project.init_supply

    # register webhook
    register_webhook import_context

    # init hyper ledger and create a special event in github_events
    # so that we can get the detail of the event by block chain transaction id
    create_ledger import_context

    # send email to others from project contributors exclude importer self.
    import_context[:import_user] = current_user.name
    notify_other_members(import_context, current_user)

    true
  end

  def create_ledger(import_context)
    unless ledger_ready(import_context[:symbol], import_context[:eth_account])
      bc_resp = init_ledger import_context
      KCoinTransaction.insert(
        eth_account_to: project.eth_account,
        transaction_id: bc_resp['transactionId'],
        transaction_type: PROJECT_IMPORT_EVENT,
        message: '项目导入',
        correlation_id: project.id,
        correlation_table: 'projects',
        created_at: Time.now
      )
    end
  end

  # @param [Object] import_context
  # @return [Object]
  def persist_project(import_context)
    if Project.project_not_exist?(import_context[:github_project_id])
      puts "Persisting project #{import_context[:github_project_id]} by user"
      DB.transaction do
        project = Project.create(name: import_context[:name],
                                 created_at: Time.now,
                                 owner: import_context[:owner],
                                 img: import_context[:img],
                                 secret: SecureRandom.hex,
                                 symbol: SecureRandom.hex,
                                 eth_account: Digest::SHA1.hexdigest(import_context[:github_project_id]),
                                 first_word: import_context[:first_word],
                                 custom_name: import_context[:custom_name],
                                 token_name: import_context[:token_name],
                                 init_supply: import_context[:init_supply],
                                 discuss_method: import_context[:discuss_method],
                                 github_project_id: import_context[:github_project_id])
        User[current_user.id].add_project(project)
      end
    else
      project = Project.get_by_github_project_id(import_context[:github_project_id])
      project.update(custom_name: import_context[:custom_name],
                     token_name: import_context[:token_name],
                     init_supply: import_context[:init_supply],
                     discuss_method: import_context[:discuss_method])
    end
  end

  # @param [Object] context
  # @param [Object] current_user
  def notify_other_members(context, current_user)
    importer = context[:contributors].select do |item|
      item['login'].eql?(current_user.login)
    end
    if importer.empty?
      raise 'you are not this project contributors,can not import!'
    end
    context[:importer_avatar_url] = importer.first['avatar_url']
    context[:importer_user] = importer.first['login']
    context[:contributors].each do |item|
      user_eth_account = Digest::SHA1.hexdigest(UserAppHelpers::GITHUB + item['id'].to_s)

      # create oauth
      oauth = Oauth.first(oauth_provider: UserAppHelpers::GITHUB, open_id: item['id'])
      unless oauth
        Oauth.insert(login: item['login'],
                     name: item['login'],
                     oauth_provider: UserAppHelpers::GITHUB,
                     open_id: item['id'],
                     eth_account: user_eth_account,
                     avatar_url: item['avatar_url'],
                     created_at: Time.now,
                     last_login_at: Time.now)
      end

      # get user email
      resp = HTTParty.get('https://api.github.com/users/' + item['login'] + '/events/public')
      mails = JSON.parse(resp.body)
      mail = mails.select do |t|
        if t['type'].eql?('PushEvent')
          (((t['payload'] || {})['commits'] || []).first['author'] || {})['email']
        end
      end
      mail = (((mail.first['payload'] || {})['commits'] || []).first['author'] || {})['email']
      # create user
      user = User.first(email: mail) || User.first(login: item['login'])
      if user.nil?
        User.insert(login: item['login'],
                    name: item['login'],
                    eth_account: user_eth_account,
                    email: mail,
                    avatar_url: nil,
                    activated: false,
                    created_at: Time.now,
                    updated_at: Time.now,
                    last_login_at: Time.now)
      end

      if UserEmail.first(email: mail).nil?
        UserEmail.insert(user_id: user.id,
                         email: mail,
                         verified: false,
                         created_at: Time.now)
      end
      # bind project to user
      if UserProject.first(project_id: context[:id], user_id: user[:id]).nil?
        UserProject.insert(project_id: context[:id], user_id: user[:id])
      end
      # send supply to blackchain
      user_init_supply = item['init_supply'] ||= item[:init_supply]
      if user_init_supply.to_i <= 0
        puts "init supply for user #{item['id']} is invalid or 0"
        return
      end
      bc_resp = transfer(context[:symbol], context[:eth_account], user_eth_account, user_init_supply.to_i)
      KCoinTransaction.insert(
        eth_account_from: context[:symbol],
        eth_account_to: user_eth_account,
        transaction_id: bc_resp['transactionId'],
        transaction_type: 'project_import',
        message: '项目导入',
        correlation_id: current_user.id,
        correlation_table: 'users',
        created_at: Time.now
      )

      # TODO: send email. Temporarily disabled due to email issue
      !importer.first[:login].eql?(current_user.login) ? send_project_import_email(context, item, mail) : next
    end
  end

  def list_user_project(user_id, kcoin_symbol)
    # return projects for display
    db_data = User[user_id].projects
    return [] if db_data.empty?

    # TODO: ideally the balances should be read asynchronously via AJAX
    accounts = []
    project_hashes = [] # filter columns, fields like `secret` should be removed from response
    db_data.each do |p|
      accounts.push p.eth_account
      # TODO: add batch query here? Or at least AJAX. To query server in a loop is bad
      token = query_balance(p.symbol, p.eth_account)
      project_hashes.push(
        id: p.id,
        name: p.name,
        custom_name: p.custom_name ||= "#{p.owner}/#{p.name}",
        owner: p.owner,
        github_project_id: p.github_project_id,
        first_word: p.first_word,
        description: p.description,
        img: p.img,
        created_at: p.created_at,
        project_token: token,
        kcoin: 0
      )
    end

    puts "query kcoin/token of user's project, user_id=#{user_id}, accounts=#{accounts}"
    bc_resp = query_balance_list(kcoin_symbol, accounts)
    bc_resp.each do |acc, bal|
      ind = accounts.find_index acc
      project_hashes[ind][:kcoin] = bal.to_i if ind
    end

    project_hashes
  end
end
