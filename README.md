# Caelus

Caelus is the open source tool for plane spotters and aviation enthusiasts. Caelus will profile flight data at your local airport(s) and notify you if something unusual is arriving or departing. 

Planned alerts include:
* Interesting aircraft types
* Known interesting livery
* Unusual airlines

## Data Providers

* [AviationStack](https://aviationstack.com)

## Getting Started

This application is still in early development, that said it will take some tinerking to get it to work for the time being. 

### Before you start

* A postgres server with database and user with permissions to create tables and write to that database
* An AviationStack API key

After you have this, create `config/config.secret.exs` with the following contents:

```
use Mix.Config

config :caelus,
  aviation_stack_api_key: "YOUR AVIATION STACK KEY HERE"
```

Then create `config/prod.secret.exs` with the following contents:

```
use Mix.Config

config :caelus, CaelusWeb.Endpoint,
  secret_key_base: "REPLACE WITH YOUR OWN STRING"

# Configure your database
config :caelus, Caelus.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "YOUR USERNAME",
  password: "YOUR PASSWORD",
  database: "YOUR DB NAME",
  hostname: "YOUR DB HOSTNAME"

```

### Running Caelus

Next run the following commands:

1. `MIX_ENV=prod PORT=4040 mix ecto.migrate`
2. `MIX_ENV=prod PORT=4040 mix deps.get`
3. `MIX_ENV=prod PORT=4040 mix phx.server`

You should see some debug output indicating that things are working! By default the scraper will only run once every 24 hours so expect to not see anything for a long time after you start it!

### "Production"

While Caelus is definitely _not_ production ready, you can run it in a "production-like" way by building a docker image using the included `Dockerfile`. With that you can run it on some machine that runs docker containers with `restart=always`. More details will be included here once Caelus moves closer to any sort of "release". 
