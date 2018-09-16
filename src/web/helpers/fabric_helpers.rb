module FabricHelpers

  FINCTION_INIT_LEDGER = 'initLedger'
  FINCTION_TRANSFER = 'transfer'
  FINCTION_BALANCE = 'balance'
  FINCTION_HISTORY_QUERY = 'historyQuery'

  def query_url
    "#{CONFIG[:server][:url].chomp('/')}/fabric/query"
  end

  def invoke_url
    "#{CONFIG[:server][:url].chomp('/')}/fabric/invoke"
  end

  def query_server(fn, args)
    # query only without writing any data to block chain
    call_server(query_url, fn, args)
  end

  def invoke_server(fn, args)
    # call invoke whenever you need to write any data to block chain
    call_server(invoke_url, fn, args)
  end

  def call_server(url, fn, args)
    options = {
      :body => {
        :fn => fn,
        :args => args,
      }.to_json,
      :headers => {
        :Accept => 'application/json',
        'Content-Type' => 'application/json'
      },
      :timeout => 120 # 2 minutes
    }
    resp = HTTParty.post(url, options)
    puts "invoke #{fn} with args #{args.to_s}, response #{resp.code}, #{resp.body}"
    raise 'Communication error with the block chain' unless resp.code/100==2
    JSON.parse(resp.body)
  end

  def init_ledger(context)
    init_supply = 10000 # TODO should be from user's input while importing project
    # using id of project as name(id of the db record, not the project_id from github)
    args = [context[:symbol], context[:id].to_s, context[:eth_account], init_supply.to_s]
    invoke_server(FINCTION_INIT_LEDGER, args)
  end

end