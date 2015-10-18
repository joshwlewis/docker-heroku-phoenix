# Inherit from Heroku's stack
FROM heroku/cedar:14
MAINTAINER Josh Lewis <josh.w.lewis@gmail.com>

# Elixir needs to be compiled against UTF-8
ENV LANG en_US.UTF-8

# To be compatible with the Heroku platform, everything needs to be in /app
ENV HOME /app
WORKDIR /app

# Create our dependency directory
RUN mkdir -p /app/docker-heroku-phoenix

# Make sure we have erlang, elixir, and node binaries on our execution path
ENV PATH /app/docker-heroku-phoenix/bin:/app/node_modules/.bin:$PATH
RUN mkdir -p /app/.profile.d \
    && echo "export PATH=\"/app/docker-heroku-phoenix/bin:/app/node_modules/.bin:\$PATH\"" \
    >  /app/.profile.d/docker-heroku-phoenix.sh

# Install Erlang/OTP
ENV ERLANG_ENGINE 18.1.2
ENV ERL_TOP /tmp/erlang
RUN mkdir -p /tmp/erlang \
    && cd /tmp/erlang \
    && curl -s https://codeload.github.com/erlang/otp/tar.gz/OTP-$ERLANG_ENGINE \
    |  tar --strip-components=1 -xz -C . \
    && ./otp_build autoconf \
    && ./configure --prefix=/app/docker-heroku-phoenix \
    && make \
    && make release_tests \
    && make install \
    && rm -rf /tmp/erlang

# Install Elixir
ENV ELIXIR_ENGINE 1.1.1
RUN mkdir -p /tmp/elixir \
    && cd /tmp/elixir \
    && curl -s https://codeload.github.com/elixir-lang/elixir/tar.gz/v$ELIXIR_ENGINE \
    |  tar --strip-components=1 -xz -C . \
    && make \
    && make test \
    && make install PREFIX=/app/docker-heroku-phoenix \
    && rm -rf /tmp/elixir

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Install Node.js (comes with NPM)
ENV NODE_ENGINE 4.2.1
RUN mkdir -p /tmp/node \
    && cd /tmp/node \
    && curl -s https://codeload.github.com/nodejs/node/tar.gz/v$NODE_ENGINE \
    |  tar --strip-components=1 -xz -C . \
    && ./configure --prefix=/app/docker-heroku-phoenix \
    && make \
    && make install \
    && rm -rf /tmp/node

# Add package manifests
ONBUILD ADD mix.exs /app
ONBUILD ADD package.json /app

# Install packages
ONBUILD RUN mix deps.get
ONBUILD RUN npm install

# Add the rest of the app and compile
ONBUILD ADD . /app
ONBUILD RUN mix compile
