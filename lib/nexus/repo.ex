defmodule Nexus.Repo do
  use Ecto.Repo,
    otp_app: :nexus,
    adapter: Ecto.Adapters.SQLite3
end
