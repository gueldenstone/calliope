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
  end

  scope "/job_stories", StorytellerWeb do
    pipe_through :browser
    live "/", JobStoryLive.Index, :index
    live "/new", JobStoryLive.Index, :new
    live "/similar", JobStoryLive.Similar, :index
    live "/:id/edit", JobStoryLive.Index, :edit

    live "/:id", JobStoryLive.Show, :show
    live "/:id/show/edit", JobStoryLive.Show, :edit
  end

  scope "/products", StorytellerWeb do
    pipe_through :browser
    live "/", ProductLive.Index, :index
    live "/new", ProductLive.Index, :new
    live "/:id/edit", ProductLive.Index, :edit

    live "/:id", ProductLive.Show, :show
    live "/:id/show/edit", ProductLive.Show, :edit
  end

  scope "/markets", StorytellerWeb do
    pipe_through :browser
    live "/", MarketLive.Index, :index
    live "/new", MarketLive.Index, :new
    live "/:id/edit", MarketLive.Index, :edit

    live "/:id", MarketLive.Show, :show
    live "/:id/show/edit", MarketLive.Show, :edit
  end

  scope "/users", StorytellerWeb do
    pipe_through :browser
    live "/", UserLive.Index, :index
    live "/new", UserLive.Index, :new
    live "/:id/edit", UserLive.Index, :edit

    live "/:id", UserLive.Show, :show
    live "/:id/show/edit", UserLive.Show, :edit
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
