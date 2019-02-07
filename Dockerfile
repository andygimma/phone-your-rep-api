FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs libgeos-dev
RUN mkdir /pyr
WORKDIR /pyr
COPY Gemfile /pyr/Gemfile
COPY Gemfile.lock /pyr/Gemfile.lock
RUN bundle install
CMD ["rails", "server"]