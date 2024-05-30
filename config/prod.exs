import Config

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# Set ElasticSearch URL for production
config :nexus, elasticsearch_url: System.get_env("ELASTICSEARCH_URL")
