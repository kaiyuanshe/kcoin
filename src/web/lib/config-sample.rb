CONFIG = {
  :login => {
    :github => {
      :client_id => '',
      :client_secret => ''
    }
  },
  :ethereum => {
    :client => 'rpc', # rpc or ipc, corresponding config must be ready
    :ipc => {
      :path => "#{ENV['HOME']}/.ethereum/geth.ipc",
      :log => false
    },
    :rpc => {
      :uri => 'http://localhost:8545',
      :log => false
    }
  },
  :cc=>{
    :address => '0x6f641c723e6c93328ea0dd1c4b0e17b7d57a8dd6'
  }
}