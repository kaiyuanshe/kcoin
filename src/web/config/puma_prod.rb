environment 'production'

threads 1,16
workers 4
preload_app!

bind 'unix:///var/run/puma.sock'
pidfile '/var/run/puma.pid'
stdout_redirect '/var/log/kcoin/kcoin-web.out.log', '/var/log/kcoin/kcoin-web.err.log', true
