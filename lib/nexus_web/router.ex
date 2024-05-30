defmodule NexusWeb.Router do
  use NexusWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", NexusWeb do
    pipe_through :api
  end
end
