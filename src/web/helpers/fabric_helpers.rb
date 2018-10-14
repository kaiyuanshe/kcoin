module FabricHelpers
  FINCTION_INIT_LEDGER = 'initLedger'.freeze
  FINCTION_TRANSFER = 'transfer'.freeze
  FINCTION_BALANCE = 'balance'.freeze
  FINCTION_BATCH_BALANCE = 'batchBalance'.freeze
  FINCTION_HISTORY_QUERY = 'historyQuery'.freeze

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
      body: {
        fn: fn,
        args: args
      }.to_json,
      headers: {
        :Accept => 'application/json',
        'Content-Type' => 'application/json'
      },
      timeout: 120 # 2 minutes
    }
    resp = HTTParty.post(url, options)
    puts "invoke #{fn} with args #{args}, response #{resp.code}, #{resp.body}"
    raise 'Communication error with the block chain' unless resp.code / 100 == 2
    JSON.parse(resp.body)
  end

  def init_ledger(context)
    # using id of project as name(id of the db record, not the project_id from github)
    args = [context[:symbol].to_s, context[:token_name].to_s, context[:eth_account].to_s, context[:init_supply].to_s]
    invoke_server(FINCTION_INIT_LEDGER, args)
  end

  def query_balance(_symbol, _eth_account)
    resp = query_server(FINCTION_BALANCE, [symbol, eth_account])
    resp['payload'].to_i
    # TODO remove
    JSON.parse('{"TotalBalance":"21","History":[{"TxId":"a963f5e561f7765906d8a6366525f9c3640b5a5c9f3605051c3280c7b3c8bf11", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:45:57.306744196 +0000 UTC"},{"TxId":"82ebf2d0338658db06cba974684460b1281f4d3cb89690cc52c9c451e9be5256", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:47:01.508385219 +0000 UTC"},{"TxId":"bc02764fc61ae3582d5ee29d3efc438e59459d5cc6b20f77e8d8cdcdde36387e", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:47:12.328307111 +0000 UTC"},{"TxId":"64c9fde5e475ce6db5c8e9a5fb476ec12ffc50ec607d7037471796324fe3f3cb", "Supply":21, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:50:42.763476109 +0000 UTC"}]}')
  end

  def query_balance_list(symbol, eth_account_list)
    if eth_account_list.is_a? Array
      args = [symbol.to_s]
      eth_account_list.each { |x| args.push x.to_s }
    else
      args = [symbol.to_s, eth_account_list.to_s]
    end

    # query_server(FINCTION_BATCH_BALANCE, args)
    []
  end

  def ledger_ready(symbol, owner)
    owner_balance = query_balance(symbol, owner)
    owner_balance > 0
  end

  def query_history(_symbol, _eth_account)
    # resp = query_server(FINCTION_HISTORY_QUERY, [symbol, eth_account])
    # resp['payload']
    # TODO remove
    JSON.parse('{"TotalBalance":"21","History":[{"TxId":"a963f5e561f7765906d8a6366525f9c3640b5a5c9f3605051c3280c7b3c8bf11", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:45:57.306744196 +0000 UTC"},{"TxId":"82ebf2d0338658db06cba974684460b1281f4d3cb89690cc52c9c451e9be5256", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:47:01.508385219 +0000 UTC"},{"TxId":"bc02764fc61ae3582d5ee29d3efc438e59459d5cc6b20f77e8d8cdcdde36387e", "Supply":9, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:47:12.328307111 +0000 UTC"},{"TxId":"64c9fde5e475ce6db5c8e9a5fb476ec12ffc50ec607d7037471796324fe3f3cb", "Supply":21, "TokenSymbol":"kcoin_dev", "Timestamp":"2018-10-14 13:50:42.763476109 +0000 UTC"}]}')
  end

  # @param [symbol_account,symbol_account] args
  def batch_query_history(_args)
    # resp = query_server(FINCTION_HISTORY_QUERY, args)
    # resp['payload']
    # TODO remove
    JSON.parse('[{"TotalBalance":"431","History":[{"TxId":"141f44c866acc4ef5e7340501c951daa214a4aa95a8073c7d759c3098ca60235", "Supply":800, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:28:17.679909003 +0000 UTC"},{"TxId":"42b1d259002ae217de40acf0e3d1f8c8588f878da5f192106444f485f119db58", "Supply":799, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:48:52.887201928 +0000 UTC"},{"TxId":"a8ad6378db8b458c87585282934095287510e488e4cda0d518d4a791a0e6901e", "Supply":788, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:49:16.138504266 +0000 UTC"},{"TxId":"7243da5be80b1bcb32f51e243aa748bd50f589a373cf52d92370ebb071275590", "Supply":677, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:49:34.791549864 +0000 UTC"},{"TxId":"42daac9cdfa8450915e315b626a343d0b6b689fc03816ade9d595fc1470e12b1", "Supply":675, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:54:16.341054752 +0000 UTC"},{"TxId":"23d2b5a9a34b534372476d512735c92220de28e9343d9d3d67fd22c3882f3ac7", "Supply":653, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:54:23.067757643 +0000 UTC"},{"TxId":"11e7dcafa23367a6f04ba9f92c1de93f10b7e12a49a265a4c244795f1e01225d", "Supply":431, "TokenSymbol":"382e1552c5405800cc796b92cacaf11c", "Timestamp":"2018-10-14 02:54:27.957247282 +0000 UTC"}]},{"TotalBalance":"739","History":[{"TxId":"f6eb012c403c3757286ca1b2ee30a53a043be22c9a2be56d9a712cb11341e29a", "Supply":1600, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 02:29:11.123523866 +0000 UTC"},{"TxId":"c79dfa3e8f968e294d1a2be9fea4ad800742517d7265b76e2949fdb1b86a4afb", "Supply":1597, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:04.437795672 +0000 UTC"},{"TxId":"3a789c2b7cf6130d986c7c19576f2a5a6c17c51f4aa3ee01dc5b1d0c73a456b6", "Supply":1564, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:08.89607383 +0000 UTC"},{"TxId":"dffa988af528a69dd205dc1709ef6cd9c29e81fb7be64827d0e9d872492aea80", "Supply":1231, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:12.345991698 +0000 UTC"},{"TxId":"8c826c35ff332d99c5a9aee178aa36f05754592099f11004afffc09a7ce7ada2", "Supply":1227, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:20.348347964 +0000 UTC"},{"TxId":"f8787b408fa8da84a495fbe39ca75bf51ad7150a48360e7095414b8e8202cd91", "Supply":1183, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:27.264165329 +0000 UTC"},{"TxId":"316caff1dbce5106f0ca71d6984b763f03d4b9b25552a08d253556a64538a5f0", "Supply":739, "TokenSymbol":"3da077260c4a7cc786e210797a953f29", "Timestamp":"2018-10-14 03:01:29.761469829 +0000 UTC"}]}]')
  end

  def transfer(symbol, from, to, amount)
    invoke_server(FINCTION_TRANSFER, [symbol, from, to, amount.to_s])
  end
end
