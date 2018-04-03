class KCoinApp
  require './routes/website'
  require './routes/auth'

  attr_reader :app

  def initialize
    @app = Rack::Builder.app do
      map('/') { run WebsiteController }
      map('/auth') { run AuthController }
      map('/assets') { run BaseController.sprockets }
    end
  end

  def call(env)
    app.call(env)
  end
end