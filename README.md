# Docker-Heroku-Phoenix

This is a Dockerfile and Docker image for use with Phoenix Framework apps on
the Heroku Platform. This is a workflow that largely replaces git push and
buildpacks.


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

Next, you'll need a Phoenix-like project to work in. At a bare minimum, 
you'll need `mix.exs` and `package.json` files. `mix phoenix.new` should have 
created these for you.

Addtionally, you'll need to create the following files via the steps below.

- Procfile
- app.json
- Dockerfile
- docker-compose.yml

Create a `Procfile` ([Documentation](https://devcenter.heroku.com/articles/procfile)):

```
web: mix phoenix.server
console: iex -S mix phoenix.server
```

Create an `app.json` ([Documentation](https://devcenter.heroku.com/articles/app-json-schema)):

```json
{
  "name": "My Cool App",
  "description": "My Cool App is powered by Phoenix and Docker!",
  "image": "joshwlewis/heroku-docker-phoenix",
  "addons": [
    "heroku-postgresql"
  ]
}
```

Now, install `heroku-docker` (if you haven't already) with `heroku
plugins:install heroku-docker`.

Now generate the additional files you'll need with `heroku docker:init`.

You'll get a `Dockerfile` should look something like this:

```Dockerfile
FROM "joshwlewis/heroku-docker-phoenix"
```

And your `docker-compose.yml` should look roughly like this:
```yaml
web:
  build: .
  command: 'bash -c ''mix phoenix.server'''
  working_dir: /app/user
  environment:
    PORT: 8080
    DATABASE_URL: 'postgres://postgres:@herokuPostgresql:5432/postgres'
  ports:
    - '8080:8080'
  links:
    - herokuPostgresql
```

Now you can start your application with docker-compose:

`docker-compose up web`

You should have access to your app running at localhost:8080. You can develop
with your normal workflow.

Before you deploy, you'll want to make sure you productionize your static
assets. This Dockerfile does not do that for you, but you can set that up
to happen after npm installs your dependencies. In your `package.json` add
this:

```json
{
  "scripts": {
    "postinstall": "brunch build && mix phoenix.digest"
  }
}
```

And finally, when you are ready to deploy, run:

`heroku docker:release`

For more on using Docker on Heroku, see the [Heroku Devcenter](https://devcenter.heroku.com/articles/docker).
For more info on the awesome Phoenix Framework, see [phoenixframework.org](https://www.phoenixframework.org).
