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

Next, you'll need a `Dockerfile` and a `docker-compose.yml`. You can either
create these manually (examples below), or you can generate them with
`heroku docker:init`.

To generate the files, first you'll need a `Procfile`. It should look like
this for a Phoenix app:

```
web: mix phoenix.server
console iex -S mix phoenix.server
```

Then you'll need an `app.json`. It should look something like this:

```
{
  "name": "My App",
  "description": "My App runs on Heroku Docker and Phoenix",
  "image": "joshwlewis/heroku-docker-phoenix",
  "addons": [
    "heroku-postgresql"
  ]
}
```

Now, [install heroku-docker](https://github.com/heroku/heroku-docker) (if you
haven't already) and run `heroku docker:init`. This should generate a 
`Dockerfile` and a `docker-compose.yml` for you.

Your `Dockerfile` should look like this:

```Dockerfile
FROM "joshwlewis/heroku-docker-phoenix"
```

And your `docker-compose.yml` should look like this:

```yaml
web:
  build: .
  command: 'bash -c ''mix phoenix.server'''
  working_dir: /app/user
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
RUN "brunch build --production && MIX_ENV=prod mix phoenix.digest"
```

Now you should be ship your image to heroku:

`heroku docker:release --app my-app`
