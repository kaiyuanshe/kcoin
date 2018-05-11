require 'ethereum.rb'
require_relative '../config'

if CONFIG[:ethereum][:client] == 'ipc'
  ipc = CONFIG[:ethereum][:ipc][:path]
  log = CONFIG[:ethereum][:ipc][:log]
  EC = Ethereum::IpcClient.new(ipc, log)
else
  host = CONFIG[:ethereum][:rpc][:uri]
  log = CONFIG[:ethereum][:rpc][:log]
  EC = Ethereum::HttpClient.new(host, nil, log)
end

