FROM ruby:2.5

WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "puma", "-C", "config/puma_prod.rb"]
