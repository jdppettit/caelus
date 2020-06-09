use Mix.Config

config :caelus, CaelusWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :caelus,
  run_scraper: false,
  run_analytics: true,
  airports: ["KMSP"]

import_config "prod.secret.exs"
