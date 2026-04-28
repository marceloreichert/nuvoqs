defmodule Nuvoqs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NuvoqsWeb.Telemetry,
      Nuvoqs.Repo,
      {DNSCluster, query: Application.get_env(:nuvoqs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nuvoqs.PubSub},
      # Start a worker by calling: Nuvoqs.Worker.start_link(arg)
      # {Nuvoqs.Worker, arg},
      # Start to serve requests, typically the last entry
      NuvoqsWeb.Endpoint,
      %{
        id: Nuvoqs.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent,
        start: {Nuvoqs.Behaviours.EventBehaviour, :start_link, [Nuvoqs.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nuvoqs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NuvoqsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
