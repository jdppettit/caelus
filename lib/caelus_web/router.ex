defmodule CaelusWeb.Router do
  use CaelusWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CaelusWeb do
    pipe_through :api
  end
end
