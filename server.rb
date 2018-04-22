class KCoinApp
  require './controllers/website'
  require './controllers/auth'
  require './controllers/user'
  require './lib/config'

  attr_reader :app

  def initialize
    @app = Rack::Builder.app do
      map('/') { run WebsiteController }
      map('/auth') { run AuthController }
      map('/user') { run UserController }
    end
  end

  def call(env)
    app.call(env)
  end
end