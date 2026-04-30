defmodule Nuvoqs.OliviaEngine.Flow.Registry do
  @moduledoc """
  ETS-backed registry for flow definitions.
  Flows can be registered at compile time (via modules using the DSL)
  or at runtime (via JSON/map definitions).
  """
  use GenServer

  @table :olivia_engine_flows

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Register a flow definition."
  @spec register(Nuvoqs.OliviaEngine.Flow.Definition.t()) :: :ok
  def register(%Nuvoqs.OliviaEngine.Flow.Definition{} = flow) do
    GenServer.call(__MODULE__, {:register, flow})
  end

  @doc "Register all flows from a module that uses the DSL."
  @spec register_module(module()) :: :ok
  def register_module(module) do
    for flow <- module.__flows__() do
      register(flow)
    end

    :ok
  end

  @doc "Look up a flow by name."
  @spec lookup(String.t()) :: {:ok, Nuvoqs.OliviaEngine.Flow.Definition.t()} | :not_found
  def lookup(name) do
    case :ets.lookup(@table, name) do
      [{^name, flow}] -> {:ok, flow}
      [] -> :not_found
    end
  end

  @doc "List all registered flow names."
  @spec list() :: [String.t()]
  def list do
    :ets.tab2list(@table)
    |> Enum.map(fn {name, _flow} -> name end)
  end

  @doc """
  Register a flow from a plain map (useful for JSON-loaded flows).

  ## Example

      Nuvoqs.OliviaEngine.Flow.Registry.register_from_map(%{
        "name" => "greet",
        "entry_node" => "start",
        "nodes" => %{
          "start" => %{
            "say" => "Hello! How can I help?",
            "transitions" => [%{"target" => "end"}]
          }
        }
      })
  """
  @spec register_from_map(map()) :: :ok
  def register_from_map(map) when is_map(map) do
    flow = parse_flow_map(map)
    register(flow)
  end

  defp parse_flow_map(map) do
    nodes =
      map
      |> Map.get("nodes", %{})
      |> Enum.into(%{}, fn {name, node_map} ->
        node = %Nuvoqs.OliviaEngine.Flow.Node{
          name: String.to_atom(name),
          say: Map.get(node_map, "say"),
          slots:
            node_map
            |> Map.get("slots", [])
            |> Enum.map(fn s ->
              %Nuvoqs.OliviaEngine.Flow.Slot{
                name: String.to_atom(s["name"]),
                entity: s["entity"],
                prompt: s["prompt"],
                required: Map.get(s, "required", true)
              }
            end),
          transitions:
            node_map
            |> Map.get("transitions", [])
            |> Enum.map(fn t ->
              %Nuvoqs.OliviaEngine.Flow.Transition{
                target: String.to_atom(t["target"]),
                condition: t["when"]
              }
            end),
          on_slots_filled:
            case Map.get(node_map, "on_slots_filled") do
              nil -> nil
              target -> String.to_atom(target)
            end,
          action:
            case Map.get(node_map, "action") do
              nil -> nil
              a -> String.to_atom(a)
            end,
          terminal: Map.get(node_map, "terminal", false)
        }

        {String.to_atom(name), node}
      end)

    %Nuvoqs.OliviaEngine.Flow.Definition{
      name: map["name"],
      nodes: nodes,
      entry_node: String.to_atom(map["entry_node"])
    }
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, flow}, _from, state) do
    :ets.insert(@table, {flow.name, flow})
    {:reply, :ok, state}
  end
end
