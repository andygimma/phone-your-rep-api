FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs libgeos-3.4.2 libgeos-dev libproj0 libproj-dev
RUN ln -s /usr/lib/libgeos-3.4.2.so /usr/lib/libgeos.so
RUN ln -s /usr/lib/libgeos-3.4.2.so /usr/lib/libgeos.so.1
RUN mkdir /pyr
WORKDIR /pyr
COPY Gemfile /pyr/Gemfile
COPY Gemfile.lock /pyr/Gemfile.lock
RUN bundle install
CMD ["rails", "server"]