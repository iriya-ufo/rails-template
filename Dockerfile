FROM ruby:3.1

ENV APP_ROOT=/opt/app/
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock $APP_ROOT

RUN bundle install

COPY . $APP_ROOT

EXPOSE 3000
