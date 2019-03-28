#FROM ubuntu:16.04

#FROM ruby:2.5.3
FROM ruby:2.6.1

ENV DISCOURSE_VERSION=2.3.0.beta5

ENV RUBY_VERSION="2.6.1"


RUN touch $HOME/.bashrc

RUN apt-get update
RUN apt-get install -y vim git build-essential 
RUN apt-get install -y libxslt1-dev libcurl4-openssl-dev libksba8 libksba-dev libqtwebkit-dev libreadline-dev libssl-dev zlib1g-dev libsnappy-dev
RUN apt-get -y install libsqlite3-dev sqlite3
RUN apt-get -y install postgresql postgresql-server-dev-all postgresql-contrib libpq-dev
RUN apt-get -y install redis-server
RUN apt-get -y install curl
RUN apt-get -y install imagemagick
RUN apt-get -y install advancecomp gifsicle jpegoptim libjpeg-progs optipng pngcrush pngquant
RUN apt-get -y install jhead

#RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
#RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build



#RUN export PATH=~/.rbenv/bin:$PATH
#RUN eval "$(~/.rbenv/bin/rbenv init - --no-rehash)"

#RUN ~/.rbenv/bin/rbenv install "${RUBY_VERSION}"
#RUN ~/.rbenv/bin/rbenv global ${RUBY_VERSION}
#RUN ~/.rbenv/bin/rbenv rehash
RUN gem update --system
RUN gem install rails
RUN gem install bundler --force
RUN gem install mailcatcher
RUN curl -sL https://deb.nodesource.com/setup_8.x |  bash -
RUN apt-get install -y nodejs
RUN npm install -g svgo

RUN npm install svgo uglify-js@"<3" -g
RUN mkdir -p /var/discourse

RUN addgroup --gid 1000 discourse \
 && adduser --system --uid 1000 --ingroup discourse --shell /bin/bash discourse \
 && cd /var/discourse \
 && mkdir -p tmp/pids \
 && mkdir -p ./tmp/sockets \
 && git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git \
 && mkdir -p /var/discourse/discourse/plugins \
 && cd /var/discourse/discourse/plugins \
 && git clone https://github.com/discourse/discourse-solved.git \
 && git clone https://github.com/discourse/discourse-voting.git \
 && git clone https://github.com/discourse/discourse-assign.git \ 
 && git clone https://github.com/angusmcleod/discourse-locations.git \
 && git clone https://github.com/angusmcleod/discourse-events.git \
 && git clone https://github.com/angusmcleod/discourse-question-answer.git \
 && git clone https://github.com/angusmcleod/discourse-ratings.git \
 && git clone https://github.com/davidtaylorhq/discourse-whos-online.git \
 && git clone https://github.com/discourse/discourse-canned-replies.git \
 && git clone https://github.com/discourse/discourse-tooltips.git \
 && git clone https://github.com/angusmcleod/discourse-topic-previews.git \
 && git clone https://github.com/angusmcleod/discourse-layouts.git \
 && git clone https://github.com/iunctis/discourse-formatting-toolbar.git \
 && cd /var/discourse/discourse \
 && chown -R discourse:discourse . \
 && git remote set-branches --add origin tests-passed \
 && sed -i 's/daemonize true/daemonize false/g' ./config/puma.rb \
 && sed -i 's/\/home\/discourse/\/var\/discourse/g' ./config/puma.rb \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --verbose --without test --without development --retry 3 --jobs 4 \
 && bundle exec rake plugin:update plugin=discourse-solved \
 && bundle exec rake plugin:update plugin=discourse-voting \
 && bundle exec rake plugin:update plugin=discourse-assign \
 && bundle exec rake plugin:update plugin=discourse-locations \
 && bundle exec rake plugin:update plugin=discourse-events \
 && bundle exec rake plugin:update plugin=discourse-question-answer \
 && bundle exec rake plugin:update plugin=discourse-ratings \
 && bundle exec rake plugin:update plugin=discourse-whos-online \
# && bundle exec rake plugin:update plugin=discourse-canned-replies \
 && bundle exec rake plugin:update plugin=discourse-tooltips \
 && bundle exec rake plugin:update plugin=discourse-topic-previews \
 && bundle exec rake plugin:update plugin=discourse-layouts \
 && bundle exec rake plugin:update plugin=discourse-formatting-toolbar

RUN find /var/discourse/discourse/vendor/bundle -name tmp -type d -exec rm -rf {} +


ADD config/sidekiq.yml /var/discourse/discourse/config
RUN chown -R discourse:discourse /var/discourse/discourse/config/sidekiq.yml

WORKDIR /var/discourse/discourse

ADD init.sh /var/discourse/discourse
RUN chmod +x  /var/discourse/discourse/init.sh
RUN chown -R discourse:discourse /var/discourse/discourse/init.sh

Add build-static.sh /var/discourse/discourse
RUN chmod +x /var/discourse/discourse/build-static.sh
#RUN chown -R discourse:discourse /var/discourse/discourse/build-static.sh

ENV RAILS_ENV=production

RUN /var/discourse/discourse/build-static.sh

RUN chown -R discourse:discourse /var/discourse/discourse

USER discourse
CMD ["/var/discourse/discourse/init.sh"]