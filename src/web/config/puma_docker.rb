environment 'production'

threads 1,16
workers 4
preload_app!

bind 'tcp://0.0.0.0:9292'
pidfile '/var/run/puma.pid'
