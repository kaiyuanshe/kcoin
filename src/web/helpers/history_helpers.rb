module HistoryHelpers

  include UserAppHelpers
  include FabricHelpers
  include GithubHelpers

  def get_history(user_id)
    # get user`s all project histroy
    result = get_list_by_user(user_id)

    result[:UserId] = user_id
    result
  end

  def get_history_by_project(symbol)
    list = get_list_by_project(symbol)
    result = handle_history(list)
    result
  end

  def handle_history(list)
    result = {}
    history = []
    list.to_enum.with_index.reverse_each do |item, index|
      event = GithubEvent.first(transaction_id: item['TxId'])
      next if event.nil?
      record = {}
      record[:EventName] = event[:github_event]
      record[:KCoin] = (item['Value'] || {})['BalanceOf'].values[0]
      record[:TokenSymbol] = (item['Value'] || {})['TokenSymbol']
      record[:Date] = DateTime.parse(item['Timestamp']).strftime('%m.%d')
      record[:Year] = DateTime.parse(item['Timestamp']).strftime('%y')
      record[:Time] = DateTime.parse(item['Timestamp']).strftime('%y.%m.%d')

      record[:ChangeNum] = if index > 0
                             record[:KCoin] - ((list[index - 1] || {})['Value'] || {})['BalanceOf'].values[0]
                           else
                             record[:KCoin]
                           end
      history << record
    end

    result[:KCoin] = (history[0] || {})[:KCoin]
    result[:History] = history

    result
  end

  def get_list_by_user(user_id)
    project_list = User[user_id].projects
    result = Hash.new
    list = []

    kcoin = 0
    project_list.each do |project|
      array = get_list_by_project(project.symbol)
      result = handle_history(array)
      kcoin += result[:KCoin].to_i
      list.concat(result[:History])
    end

    result[:History] = list
    result[:KCoin] = kcoin
    result
  end

  def get_list_by_project(symbol)
    # query_history(symbol)
    # TODO: remove
    text = ''
    if 'symbol'.eql?(symbol)
      text = '[{"TxId":"b7d662edae52186194781646ae3e3c868d4cb97b8f16b01860aecc2a423ac7ed", "Value":{"Owner":"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6","TotalSupply":10000,"TokenName":"1","TokenSymbol":"62abdd781a6d27bf19840cf289bcb8a9","BalanceOf":{"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6":10000}}, "Timestamp":"2018-10-08 13:17:20.130513203 +0000 UTC"},{"TxId":"9c81c8ac32e9bec1687846c2bd0a3dcda6a00b615b48ccfb401620f566d13814", "Value":{"Owner":"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6","TotalSupply":10000,"TokenName":"1","TokenSymbol":"62abdd781a6d27bf19840cf289bcb8a9","BalanceOf":{"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6":9900,"owner":100}}, "Timestamp":"2018-10-08 13:19:12.385598001 +0000 UTC"},{"TxId":"b2cd7b6a994cf7e09bb7ac59f3ab8b00f2a558a0972cf097fffb996bb6fd6c34", "Value":{"Owner":"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6","TotalSupply":10000,"TokenName":"1","TokenSymbol":"62abdd781a6d27bf19840cf289bcb8a9","BalanceOf":{"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6":9700,"owner":300}}, "Timestamp":"2018-10-08 13:19:18.495595405 +0000 UTC"},{"TxId":"36dcd47a80c581fee511a03c7d33bcc7a1d12381b5fc3487a1aaf92bc0acc7d7", "Value":{"Owner":"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6","TotalSupply":10000,"TokenName":"1","TokenSymbol":"62abdd781a6d27bf19840cf289bcb8a9","BalanceOf":{"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6":9400,"owner":600}}, "Timestamp":"2018-10-08 13:19:22.773348494 +0000 UTC"},{"TxId":"006eea8968a6f9e8ed56c104df94e69c00daf4ca498d7a7c6b198e90fe21186a", "Value":{"Owner":"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6","TotalSupply":10000,"TokenName":"1","TokenSymbol":"62abdd781a6d27bf19840cf289bcb8a9","BalanceOf":{"78d9a9117fde43ba3b1154f34e8c5651df1ce6d6":9100,"owner":600,"owner1":300}}, "Timestamp":"2018-10-08 23:06:47.744406213 +0000 UTC"}]'
    else
      text = '[{"TxId":"aa7a4c44ceffb2fd062d8d5336cf6bed3a0bcdb8b00c54c7b752ec34d74278f4", "Value":{"Owner":"owner","TotalSupply":10000,"TokenName":"name","TokenSymbol":"symbol","BalanceOf":{"owner":10000}}, "Timestamp":"2018-10-08 13:05:46.699488085 +0000 UTC"},{"TxId":"6e0be07a09bd22286fc16dcef65a0c245e5630514bfd1e84e982405e92cf0542", "Value":{"Owner":"owner","TotalSupply":10000,"TokenName":"name","TokenSymbol":"symbol","BalanceOf":{"owner":9990,"user1":10}}, "Timestamp":"2018-10-09 03:30:38.555738521 +0000 UTC"}]'
    end
    JSON.parse(text)
  end

  def group_history(history)
    result = []
    array = history[:History].group_by {|h| h[:TokenSymbol]}.values
    array.each do |item|
      record = {}
      record[:KCoin] = (item[0] || {})[:KCoin]
      record[:TokenSymbol] = (item[0] || {})[:TokenSymbol]
      record[:History] = item
      project = Project.first(symbol: record[:TokenSymbol])
      record[:ProjectName] = project[:name]
      record[:Img] = project[:img]
      result << record
    end
    result
  end
end