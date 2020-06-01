# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :caelus,
  ecto_repos: [Caelus.Repo]

# Configures the endpoint
config :caelus, CaelusWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "p6FKLUO29QLdKbiAinDe/AZt0rbolt5kRSpEhSW4ZBlvNZIDzSu7WZL9Xzanjao8",
  render_errors: [view: CaelusWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
