CONFIG = {
  github: {
    client_id: ENV['GITHUB_CLIENT_ID'],
    client_secret: ENV['GITHUB_CLIENT_SECRET'],
    sign_event: true
  },
  server: {
    url: ENV['SERVER_URL']
  },
  email: {
    form: ENV['EMAIL_FROM'],
    address: ENV['EMAIL_ADDRESS'],
    port: 587,
    helo: ENV['EMAIL_HELO'],
    user: ENV['EMAIL_USER'],
    secret: ENV['EMAIL_SECRET'],
    account: ENV['EMAIL_ACCOUNT']
  }
}.freeze
