class KCoinApp
  Dir.glob('./controllers/*.rb').each {|file| require file}
  require './lib/config'

  attr_reader :app

  def initialize
    @app = Rack::Builder.app do
      map('/') {run WebsiteController}
      map('/auth') {run AuthController}
      map('/user') {run UserController}
      map('/project') {run ProjectController}
      map('/api') {run ApiController}
      map('/admin') {run AdminController}
      map('/exchange') {run ExchangeController}
    end
  end

  def call(env)
    app.call(env)
  end
end