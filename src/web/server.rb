class KCoinApp
  require './controllers/website'
  require './controllers/auth'
  require './controllers/user'
  require './controllers/project'
  require './controllers/webhook'
  require './lib/config'
  require './lib/email_params'

  attr_reader :app

  def initialize
    @app = Rack::Builder.app do
      map('/') {run WebsiteController}
      map('/auth') {run AuthController}
      map('/user') {run UserController}
      map('/project') {run ProjectController}
      map('/webhook') {run WebhookController}
    end
  end

  def call(env)
    app.call(env)
  end
end