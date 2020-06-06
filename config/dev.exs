use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :caelus, CaelusWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :caelus, Caelus.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "caelus",
  password: "caelustest",
  database: "caelus_dev",
  hostname: "localhost",
  pool_size: 10

config :caelus,
  run_scraper: false,
  airports: ["KMSP"]
