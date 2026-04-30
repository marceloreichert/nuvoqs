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
      # %{
      #   id: Nuvoqs.Miner.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent,
      #   start:
      #     {Nuvoqs.Miner.Behaviours.EventBehaviour, :start_link,
      #      [Nuvoqs.Miner.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent]}
      # },
      # Registry for looking up sessions by session_id
      {Registry, keys: :unique, name: Nuvoqs.OliviaEngine.SessionRegistry},
      # DynamicSupervisor for session GenServers
      {DynamicSupervisor, name: Nuvoqs.OliviaEngine.SessionSupervisor, strategy: :one_for_one},
      # Flow registry (ETS-backed, stores flow definitions)
      Nuvoqs.OliviaEngine.Flow.Registry,
      # Actions registry (GenServer, stores action handlers)
      Nuvoqs.OliviaEngine.Flow.Actions,
      # Bumblebee NLU: embedding (intent) + NER models
      Nuvoqs.OliviaEngine.NLU.BumblebeeNLU.intent_serving_spec(),
      Nuvoqs.OliviaEngine.NLU.BumblebeeNLU.ner_serving_spec(),
      NuvoqsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nuvoqs.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    # --- Registrar flows e actions APÓS o supervisor subir ---
    register_flows()
    register_actions()

    {:ok, pid}
  end

  defp register_flows do
    # Registra todos os flows definidos via DSL.
    # Adicione seus módulos aqui:
    Nuvoqs.OliviaEngine.Flow.Registry.register_module(Nuvoqs.OliviaEngine.Examples.BookFlight)
    # Nuvoqs.OliviaEngine.Flow.Registry.register_module(MyApp.Flows.OrderPizza)
    # Nuvoqs.OliviaEngine.Flow.Registry.register_module(MyApp.Flows.Support)
  end

  defp register_actions do
    alias Nuvoqs.OliviaEngine.Flow.Actions

    # Cada action é uma função que recebe o contexto (com slots preenchidos)
    # e retorna {:ok, "mensagem"} ou :ok

    Actions.register(:book_flight, fn ctx ->
      dest = ctx.slots[:destination]
      date = ctx.slots[:date]
      {:ok, "Voo para #{dest} em #{date} confirmado! Ref: ##{:rand.uniform(99999)}"}
    end)

    # Actions.register(:order_pizza, fn ctx ->
    #   flavor = ctx.slots[:flavor]
    #   size = ctx.slots[:size]
    #   {:ok, "Pizza #{flavor} #{size} a caminho! Pedido ##{:rand.uniform(9999)}"}
    # end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NuvoqsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
