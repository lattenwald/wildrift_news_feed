defmodule WildriftNewsFeed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:wildrift_news_feed, :port, 4093)

    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: WildriftNewsFeed.Router, options: [port: port])
    ]

    opts = [strategy: :one_for_one, name: WildriftNewsFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
