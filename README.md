# Docker-Heroku-Phoenix

This is a Dockerfile and Docker image for use with Phoenix Framework apps on
the Heroku Platform. This is a workflow that largely replaces git push and
buildpacks and offers a higher level of dev-prod parity. For more on the
workflow, checkout the [Heroku Devcenter](https://devcenter.heroku.com/articles/docker).

This image a bit more generic than the title lets on. It's not tied to any
Phoenix libraries or Brunch, so it's feasible for use on any project that is
built on Elixir and Node that you'd like to deploy to Heroku.

## What this does:

- Starts from the base [heroku/cedar:14](https://hub.docker.com/r/heroku/nodejs/) docker image.
- Builds and Installs [Erlang](https://www.erlang.org) from source.
- Builds and Installs [Elixir](https://elixir-lang.org) from source.
- Builds and Installs [Node.js](https://nodejs.org) from source.
- Installs [Hex](https://hex.pm), the package manager for Elixir.
- Installs [NPM](https://npmjs.org), the package manager for Node.

## Example Usage:

A Dockerfile for a vanilla Phoenix app going to prod would look like this:

```
FROM joshwlewis/docker-heroku-phoenix:latest

# Compile elixir files for production
ENV MIX_ENV prod
# This prevents us from installing devDependencies
ENV NODE_ENV production
# This causes brunch to build minified and hashed assets
ENV BRUNCH_ENV production

# We add manifests first, to cache deps on successive rebuilds
COPY ["mix.exs", "mix.lock", "/app/user/"]
RUN mix deps.get

# Again, we're caching node_modules if you don't change package.json
ADD package.json /app/user/
RUN npm install

# Add the rest of your app, and compile for production
ADD . /app/user/
RUN mix compile \
    && brunch build \
    && mix phoenix.digest
```

And your docker-compose would look like this:

```
web:
  build: .
  command: 'bash -c ''mix phoenix.server'''
  dockerfile: Dockerfile.prod
  working_dir: /app/user
  environment:
    LANG: en_US.UTF-8
    HOST: localhost
    PORT: 4000
    DATABASE_URL: 'postgres://postgres:@postgres:4000/api_prod'
  ports:
    - '4000:4000'
  links:
    - postgres
postgres:
  image: postgres
```

