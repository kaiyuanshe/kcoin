class KCoinApp
  require './controllers/website'
  require './controllers/auth'
  require './controllers/user'
  require './controllers/project'
  require './controllers/api'
  require './lib/config'
  require './lib/email_params'

  attr_reader :app

  def initialize
    @app = Rack::Builder.app do
      map('/') {run WebsiteController}
      map('/auth') {run AuthController}
      map('/user') {run UserController}
      map('/project') {run ProjectController}
      map('/api') {run ApiController}
    end
  end

  def call(env)
    app.call(env)
  end
end