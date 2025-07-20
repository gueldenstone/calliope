defmodule StorytellerWeb.Router do
  use StorytellerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StorytellerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StorytellerWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/job_stories", JobStoryLive.Index, :index
    live "/job_stories/new", JobStoryLive.Index, :new
    live "/job_stories/:id/edit", JobStoryLive.Index, :edit

    live "/job_stories/:id", JobStoryLive.Show, :show
    live "/job_stories/:id/show/edit", JobStoryLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", StorytellerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:storyteller, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StorytellerWeb.Telemetry
    end
  end
end
