use Mix.Config

config :caelus,
  ecto_repos: [Caelus.Repo]

config :caelus, CaelusWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "p6FKLUO29QLdKbiAinDe/AZt0rbolt5kRSpEhSW4ZBlvNZIDzSu7WZL9Xzanjao8",
  render_errors: [view: CaelusWeb.ErrorView, accepts: ~w(json)]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

import_config "#{Mix.env}.exs"
import_config "config.secret.exs"

