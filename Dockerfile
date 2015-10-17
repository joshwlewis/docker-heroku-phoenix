# Inherit from Heroku's stack
FROM heroku/cedar:14
MAINTAINER Josh Lewis <josh.w.lewis@gmail.com>

# Elixir needs to be compiled against UTF-8
ENV LANG en_US.UTF-8
# Mix needs $HOME to install archives (like hex, rebar)
ENV HOME /app

# Various dependency versions
ENV ERLANG_ENGINE 18.1.2
ENV ELIXIR_ENGINE 1.1.1
ENV NODE_ENGINE 4.2.1

# Make sure we have erlang, elixir, and node binaries on our execution path
ENV PATH /app/heroku/phoenix/bin:/app/user/node_modules/.bin:$PATH

# Make required directories
RUN mkdir -p /app/.profile.d /app/heroku/phoenix /tmp/erlang /tmp/elixir /tmp/nodejs

# Erlang/OTP
WORKDIR /tmp/erlang
ENV ERL_TOP /tmp/erlang
RUN curl -s https://codeload.github.com/erlang/otp/tar.gz/OTP-$ERLANG_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN ./otp_build autoconf && ./configure --prefix=/app/heroku/phoenix
RUN make && make release_tests && make install

# Elixir
WORKDIR /tmp/elixir
RUN curl -s https://codeload.github.com/elixir-lang/elixir/tar.gz/v$ELIXIR_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN make && make test && make install PREFIX=/app/heroku/phoenix

# NodeJS
WORKDIR /tmp/nodejs
RUN curl -s https://codeload.github.com/nodejs/node/tar.gz/v$NODE_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN ./configure --prefix=/app/heroku/phoenix && make && make install

WORKDIR /app/user
RUN mix local.hex --force && mix local.rebar --force

# Cleanup build artifacts
RUN rm -rf /tmp/erlang /tmp/elixir /tmp/nodejs

# Make sure the path is always loaded correctly.
RUN echo "export PATH=\"/app/heroku/phoenix/bin:/app/user/node_modules/.bin:\$PATH\"" > /app/.profile.d/phoenix.sh

ONBUILD ADD . /app/user/
ONBUILD RUN mix deps.get && mix deps.compile
ONBUILD RUN npm install
