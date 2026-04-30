defmodule NuvoqsWeb.FlowController do
  use Phoenix.Controller, formats: [:json]

  alias Nuvoqs.OliviaEngine.Flow.Registry

  @doc "GET /api/flows - List all registered flows"
  def index(conn, _params) do
    flows = Registry.list()
    json(conn, %{flows: flows})
  end

  @doc """
  POST /api/flows - Register a flow from JSON

  Body example:
    {
      "name": "book_flight",
      "entry_node": "greeting",
      "nodes": {
        "greeting": {
          "say": "Where would you like to fly?",
          "transitions": [{"target": "collect_info"}]
        },
        "collect_info": {
          "slots": [
            {"name": "destination", "entity": "wit$location", "prompt": "Which city?"},
            {"name": "date", "entity": "wit$datetime", "prompt": "When?"}
          ],
          "on_slots_filled": "confirm"
        },
        "confirm": {
          "say": "Flying to {{destination}} on {{date}}. Confirm?",
          "transitions": [
            {"target": "done", "when": "confirm"},
            {"target": "collect_info", "when": "deny"}
          ]
        },
        "done": {
          "say": "Booked! Have a great trip.",
          "action": "book_flight",
          "terminal": true
        }
      }
    }
  """
  def create(conn, params) do
    case validate_flow(params) do
      :ok ->
        Registry.register_from_map(params)

        conn
        |> put_status(201)
        |> json(%{ok: true, flow: params["name"]})

      {:error, reason} ->
        conn
        |> put_status(422)
        |> json(%{error: reason})
    end
  end

  defp validate_flow(params) do
    cond do
      not is_binary(params["name"]) ->
        {:error, "name is required"}

      not is_binary(params["entry_node"]) ->
        {:error, "entry_node is required"}

      not is_map(params["nodes"]) or map_size(params["nodes"]) == 0 ->
        {:error, "nodes must be a non-empty map"}

      not Map.has_key?(params["nodes"], params["entry_node"]) ->
        {:error, "entry_node '#{params["entry_node"]}' not found in nodes"}

      true ->
        :ok
    end
  end
end
