FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
  git curl build-essential libssl-dev libreadline-dev \
  zlib1g-dev libyaml-dev libffi-dev autoconf && \
  rm -rf /var/lib/apt/lists/*

# Install rbenv + ruby-build
RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build
ENV PATH="/root/.rbenv/shims:/root/.rbenv/bin:$PATH"

# Install Ruby version from .ruby-version
COPY .ruby-version /app/.ruby-version
WORKDIR /app
RUN rbenv install "$(cat .ruby-version)" && rbenv global "$(cat .ruby-version)"

# Install gems (layered for caching)
RUN gem install bundler
COPY Gemfile Gemfile.lock drcheckr.gemspec /app/
COPY lib/drcheckr/version.rb /app/lib/drcheckr/version.rb
RUN bundle install

# Copy full project
COPY . /app/

CMD ["bundle", "exec", "rake", "test"]
