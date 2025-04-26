# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :diploma,
  ecto_repos: [Diploma.Repo]

# Configures the endpoint
config :diploma, DiplomaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "02LxD1BIdu2fKw8Br4uMyaPukKJVCSTbK1viXyJn24ysGVCin2RD9rr3i2JuCp6k",
  render_errors: [view: DiplomaWeb.ErrorView, accepts: ~w(html json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
