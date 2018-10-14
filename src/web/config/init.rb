Bundler.require(:default)
require 'sinatra/sequel'
require 'sqlite3'

configure :development do
  set :database, 'sqlite://kcoin.sqlite'
end

configure :production do
  set :database, 'sqlite://kcoin.sqlite'
end

configure :test do
  set :database, 'sqlite::memory:'
end

DB = settings.database
DB.extension(:pagination)

Dir['./config/migrations/*.rb'].each {|migration|
  require migration
}

Sequel::Model.strict_param_setting = false

Dir['./models/*.rb'].each {|model|
  require model
}

Role.find_role_or_create('admin')

# temp code for coscon 2018, can be safely delete after 18-10-22
filename = "#{File.dirname(__FILE__)}/coscon18.tmp"
if File.exist? filename
  File.readlines(filename).each do |line|
    CosconPoll2018.import line
  end
end