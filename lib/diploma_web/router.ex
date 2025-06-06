defmodule DiplomaWeb.Router do
  use DiplomaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DiplomaWeb do
    pipe_through :browser
  end

  # Other scopes may use custom stacks.
  # scope "/api", DiplomaWeb do
  #   pipe_through :api
  # end
end
