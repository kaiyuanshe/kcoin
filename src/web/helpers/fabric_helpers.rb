module FabricHelpers
  FINCTION_INIT_LEDGER = 'initLedger'.freeze
  FINCTION_TRANSFER = 'transfer'.freeze
  FINCTION_BALANCE = 'balance'.freeze
  FINCTION_BATCH_BALANCE = 'batchBalance'.freeze
  FINCTION_HISTORY_QUERY = 'historyQuery'.freeze
  FINCTION_BATCH_HISTORY_QUERY = 'batchHistoryQuery'.freeze
  FINCTION_ADD = 'add'.freeze

  def query_url
    "./fabric_proxy query"
  end

  def invoke_url
    "./fabric_proxy invoke"
  end

  def query_server(fn, args)
    call_server(query_url, fn, args)
  end

  def invoke_server(fn, args)
    call_server(invoke_url, fn, args)
  end

  def call_server(url, fn, args)
    command = url + " " + fn + " " + args.join(" ")
    puts command+"\n"
    data = `#{command}`
    if data.index("\"")
      data = data.gsub("\\\"","\"")
      if data.index("\"")==0
        data = data [1..-3] 
      end
    end
    puts data+"\n"
    puts "========"
    JSON.parse(data)
  end

  def init_ledger(context)
    # using id of project as name(id of the db record, not the project_id from github)
    args = [context[:symbol].to_s, context[:token_name].to_s, context[:eth_account].to_s, context[:init_supply].to_s]
    invoke_server(FINCTION_INIT_LEDGER, args)
  end

  def query_balance(symbol, eth_account)
    resp = query_server(FINCTION_BALANCE, [symbol, eth_account])
  end

  def query_balance_list(symbol, eth_account_list)
    if eth_account_list.is_a? Array
      args = [symbol.to_s]
      eth_account_list.each {|x| args.push x.to_s}
    else
      args = [symbol.to_s, eth_account_list.to_s]
    end

    resp = query_server(FINCTION_BATCH_BALANCE, args)
  end

  def ledger_ready(symbol, owner)
    owner_balance = query_balance(symbol, owner)
    owner_balance > 0
  end

  def query_history(symbol, eth_account)
    resp = query_server(FINCTION_HISTORY_QUERY, [symbol, eth_account])
  end

  # @param [symbol_account,symbol_account] args
  def batch_query_history(args)
    resp = query_server(FINCTION_BATCH_HISTORY_QUERY, args)
  end

  def transfer(symbol, from, to, amount)
    invoke_server(FINCTION_TRANSFER, [symbol, from, to, amount.to_i.to_s]) if amount.to_i > 0
  end

  def add(symbol, to, amount)
    invoke_server(FINCTION_ADD, [symbol, to, amount.to_i.to_s]) if amount.to_i > 0
  end

end
