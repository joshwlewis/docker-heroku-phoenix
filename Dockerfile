# This Dockerfile is intended for use with the Phoenix web framework on Heroku.
# It comes with:
# - Erlang
# - Elixir
# - NodeJs

# Inherit from Heroku's stack
FROM heroku/cedar:14

# Internally, we arbitrarily use port 3000
ENV PORT 3000

# Elixir needs to be compiled against UTF-8
ENV LANG en_US.UTF-8

# Various dependency versions
ENV ERLANG_ENGINE 18.0.2
ENV ELIXIR_ENGINE 1.1.1
ENV NODE_ENGINE 0.12.2

# Make sure we have erlang, elixir, and node binaries on our execution path
ENV PATH /app/phoenix/bin:/app/user/node_modules/.bin:$PATH

# Make required directories
RUN mkdir -p /app/.profile.d /app/phoenix
RUN mkdir -p /app/tmp/erlang /app/tmp/elixir /app/tmp/nodejs

# Erlang/OTP
WORKDIR /app/tmp/erlang
ENV ERL_TOP /app/tmp/erlang
RUN curl -s https://codeload.github.com/erlang/otp/tar.gz/OTP-$ERLANG_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN ./otp_build autoconf
RUN ./configure --prefix=/app/phoenix
RUN make
RUN make release_tests
RUN make install

# Elixir
WORKDIR /app/tmp/elixir
RUN curl -s https://codeload.github.com/elixir-lang/elixir/tar.gz/v$ELIXIR_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN make
RUN make test
RUN make install PREFIX=/app/phoenix

RUN echo `elixir --version`

# NodeJS
WORKDIR /app/tmp/nodejs
RUN curl -s https://codeload.github.com/nodejs/node/tar.gz/v$NODE_ENGINE \
    | tar --strip-components=1 -xz -C .
RUN ./configure --prefix=/app/phoenix
RUN make
RUN make install


WORKDIR /app/user

# Cleanup build artifacts
RUN rm -rf /app/tmp/erlang app/tmp/elixir

# Make sure the path is always loaded correctly.
RUN echo "export PATH=\"/app/phoenix/bin:/app/user/node_modules/.bin:\$PATH\"" > /app/.profile.d/phoenix.sh

RUN echo `elixir --version`
RUN echo `node --version`
RUN echo `npm --version`

ONBUILD ADD . /app/user/
ONBUILD RUN npm install
ONBUILD RUN mix deps.get

