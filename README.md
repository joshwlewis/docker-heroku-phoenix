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
- Installs your project's Hex dependencies via `mix deps.get`.
- Installs your project's npm dependencies via `npm install`.

## Usage:

First, you'll need `docker` and `docker-compose`. If you don't have them, the
[Docker Toolbox](https://docker.com/toolbox) is a nice way to get them.

Then you'll need a Phoenix-like project. At a bare minimum, you'll need a
`mix.exs` and a `package.json` to use this image. `mix phoenix.new` would
have created those for you.

Next create a `Dockerfile` in the root of your project that looks like this:

```Dockerfile
FROM "joshwlewis/heroku-docker-phoenix"
```

And a `docker-compose.yml` that looks like this:

```yaml
web:
  build: .
  command: 'bash -c ''mix phoenix.server'''
  working_dir: /app
  environment:
    PORT: 4000
    DATABASE_URL: 'postgres://postgres:@herokuPostgresql:5432/postgres'
  ports:
    - '4000:4000'
  links:
    - herokuPostgresql
herokuPostgresql:
  image: postgres
```

Now you can start your application with docker-compose:

`docker-compose up web`

You should have access to your app running at <docker-ip>:4000. You can develop
with your normal workflow.

Before you go any further, you may need to make some adjustments to your
project to prepare it for Heroku. There's some great documentation for that
[here](http://www.phoenixframework.org/docs/heroku).

Additionally, before you deploy your image, you may need to make sure that your
image gets built with productionized assets. If you are using Phoenix's brunch
setup you can just add a line to your Dockerfile:

```
RUN "brunch build && mix phoenix.digest"
```

To deploy, you'll need to get the docker plugin for Heroku's CLI:

`heroku plugins:install heroku-docker`

Then you can deploy with:

`heroku docker:release`
