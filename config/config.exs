# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :nexus,
  ecto_repos: [Nexus.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :nexus, NexusWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: NexusWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Nexus.PubSub,
  live_view: [signing_salt: "AfWK1U58"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Get Elasticsearch credentials
config :nexus, elasticsearch_username: System.get_env("ELASTICSEARCH_USERNAME")
config :nexus, elasticsearch_password: System.get_env("ELASTICSEARCH_PASSWORD")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
