require 'sinatra/base'
require 'multi_json'

# Backbone send the data into body no into the url
# https://github.com/aj0strow/sinatra-json_body_params

module Sinatra
  module JsonBodyParams

    def self.registered(app)
      app.before do
        params.merge! json_body_params
      end

      app.helpers do
        def json_body_params
          @json_body_params ||= begin
            MultiJson.load(request.body.read.to_s, symbolize_keys: true)
          rescue MultiJson::LoadError
            {}
          end
        end
      end
    end

  end
end