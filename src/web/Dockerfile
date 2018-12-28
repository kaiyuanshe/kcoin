FROM ruby:2.5

WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
COPY lib/config-docker.rb lib/config.rb

CMD ["bundle", "exec", "puma", "-C", "config/puma_docker.rb"]
