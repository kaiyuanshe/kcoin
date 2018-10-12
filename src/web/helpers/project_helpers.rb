module ProjectHelpers

  include EmailHelpers
  include GithubHelpers
  include FabricHelpers

  def import_project(import_context)
    # save project
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
                                 discuss_method: import_context[:discuss_method],
                                 github_project_id: import_context[:github_project_id])
        User[current_user.id].add_project(project)
      end
    end


    project = Project.get_by_github_project_id(import_context[:github_project_id])
    import_context[:id] = project.id
    import_context[:token_name] = project.id
    import_context[:secret] = project.secret
    import_context[:symbol] = project.symbol
    import_context[:eth_account] = project.eth_account
    import_context[:init_supply] = project.init_supply
    # register webhook
    # register_webhook import_context

    # init hyper ledger and create a special event in github_events
    # so that we can get the detail of the event by block chain transaction id
    unless ledger_ready(import_context[:symbol], import_context[:eth_account])
      bc_resp = init_ledger import_context
      GithubEvent.insert(github_delivery_id: project.symbol,
                         github_event: PROJECT_IMPORT_EVENT,
                         sender_login: current_user.login,
                         sender_id: current_user.id,
                         repository_name: project.name,
                         repository_id: project.github_project_id,
                         repository_full_name: project.name,
                         repository_owner_login: current_user.login,
                         repository_owner_id: current_user.id,
                         received_at: Time.now,
                         payload: bc_resp.to_s,
                         transaction_id: bc_resp['transactionId'],
                         processing_time: Time.now,
                         processing_state: WEBHOOK_EVENT_STATUS_PERSISTED)
    end

    # send email to other member from project
    import_context[:import_user] = current_user.name
    # send_project_import_email(import_context, current_user)
    
    true
  end

  def list_user_project(user_id, kcoin_symbol)
    # return projects for display
    db_data = User[user_id].projects
    return [] unless db_data.length>0

    #TODO ideally the balances should be read asynchronously via AJAX
    accounts = []
    project_hashes = [] # filter columns, fields like `secret` should be removed from response
    db_data.each do |p|
      accounts.push p.eth_account
      #TODO add batch query here? Or at least AJAX. To query server in a loop is bad
      token = query_balance(p.symbol, p.eth_account)
      project_hashes.push({
                            :id => p.id,
                            :name => p.name,
                            :owner => p.owner,
                            :first_word => p.first_word,
                            :description => p.description,
                            :img => p.img,
                            :created_at => p.created_at,
                            :project_token => token,
                            :kcoin => 0
                          })

    end

    puts "query kcoin/token of user's project, user_id=#{user_id.to_s}, accounts=#{accounts.to_s}"
    kcoin_balance_resp = query_balance_list(kcoin_symbol, accounts)
    payload = JSON.parse(kcoin_balance_resp['payload'])
    payload.each do |acc, bal|
      ind = accounts.find_index acc
      if ind
        project_hashes[ind][:kcoin] = bal.to_i
      end
    end

    project_hashes
  end

end
