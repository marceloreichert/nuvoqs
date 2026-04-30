defmodule Nuvoqs.OliviaEngine.Flow.Engine do
  @moduledoc """
  Executes dialog flow nodes. Handles:
  - Entering a node and producing its "say" response
  - Collecting slots from NLU results
  - Evaluating transitions based on intents
  - Running actions when a node is reached
  """

  alias Nuvoqs.OliviaEngine.Flow.{Registry, Definition, Node}
  alias Nuvoqs.OliviaEngine.NLU

  require Logger

  @type context :: %{
          flow_name: String.t() | nil,
          current_node: atom() | nil,
          slots: map(),
          history: [atom()],
          metadata: map()
        }

  @doc "Creates a fresh dialog context."
  @spec new_context() :: context()
  def new_context do
    %{
      flow_name: nil,
      current_node: nil,
      slots: %{},
      history: [],
      metadata: %{}
    }
  end

  @doc """
  Starts a specific flow, entering its first node.
  Returns the updated context and any responses to send.
  """
  @spec start_flow(context(), String.t()) :: {:ok, context(), [String.t()]} | {:error, term()}
  def start_flow(ctx, flow_name) do
    case Registry.lookup(flow_name) do
      {:ok, %Definition{entry_node: entry} = flow} ->
        ctx = %{ctx | flow_name: flow_name, current_node: entry, slots: %{}, history: []}
        enter_node(ctx, flow, entry)

      :not_found ->
        {:error, :flow_not_found}
    end
  end

  @doc """
  Processes a user message within the current flow context.
  Uses the NLU result to fill slots and evaluate transitions.
  """
  @spec process_message(context(), map()) ::
          {:ok, context(), [String.t()]} | {:error, term()}
  def process_message(%{flow_name: nil} = ctx, nlu_result) do
    # No active flow - try to match intent to a flow
    case resolve_flow_from_intent(nlu_result) do
      {:ok, flow_name} ->
        start_flow(ctx, flow_name)

      :no_match ->
        {:ok, ctx, ["I'm not sure what you'd like to do. Can you rephrase that?"]}
    end
  end

  def process_message(%{flow_name: flow_name, current_node: node_name} = ctx, nlu_result) do
    case Registry.lookup(flow_name) do
      {:ok, flow} ->
        node = Map.fetch!(flow.nodes, node_name)
        ctx = fill_slots_from_nlu(ctx, node, nlu_result)

        cond do
          has_unfilled_required_slots?(node, ctx.slots) ->
            prompt = next_slot_prompt(node, ctx.slots)
            {:ok, ctx, [prompt]}

          node.on_slots_filled != nil ->
            ctx = %{ctx | history: [node_name | ctx.history]}
            enter_node(ctx, flow, node.on_slots_filled)

          true ->
            evaluate_transitions(ctx, flow, node, nlu_result)
        end

      :not_found ->
        {:error, :flow_not_found}
    end
  end

  # --- Private ---

  defp enter_node(ctx, flow, node_name) do
    node = Map.fetch!(flow.nodes, node_name)
    ctx = %{ctx | current_node: node_name, history: [node_name | ctx.history]}

    responses = []

    # Execute action if present
    responses =
      case node.action do
        nil ->
          responses

        action_name ->
          case Nuvoqs.OliviaEngine.Flow.Actions.execute(action_name, ctx) do
            {:ok, msg} -> responses ++ [msg]
            _ -> responses
          end
      end

    # Add "say" message with slot interpolation
    responses =
      case node.say do
        nil -> responses
        text -> responses ++ [interpolate(text, ctx.slots)]
      end

    if node.terminal do
      # Reset context after terminal node
      {:ok, new_context(), responses}
    else
      if node.slots != [] and has_unfilled_required_slots?(node, ctx.slots) do
        prompt = next_slot_prompt(node, ctx.slots)
        {:ok, ctx, responses ++ [prompt]}
      else
        {:ok, ctx, responses}
      end
    end
  end

  defp fill_slots_from_nlu(ctx, node, nlu_result) do
    filled =
      node.slots
      |> Enum.reduce(ctx.slots, fn slot, acc ->
        if Map.has_key?(acc, slot.name) do
          acc
        else
          value = NLU.get_entity(nlu_result, slot.entity || to_string(slot.name))

          if value do
            Map.put(acc, slot.name, value)
          else
            acc
          end
        end
      end)

    %{ctx | slots: filled}
  end

  defp has_unfilled_required_slots?(node, filled_slots) do
    node.slots
    |> Enum.filter(& &1.required)
    |> Enum.any?(fn slot -> not Map.has_key?(filled_slots, slot.name) end)
  end

  defp next_slot_prompt(node, filled_slots) do
    node.slots
    |> Enum.filter(& &1.required)
    |> Enum.find(fn slot -> not Map.has_key?(filled_slots, slot.name) end)
    |> case do
      nil -> "Please continue."
      slot -> slot.prompt || "Please provide #{slot.name}."
    end
  end

  defp evaluate_transitions(ctx, flow, node, nlu_result) do
    intent = NLU.top_intent(nlu_result)

    transition =
      node.transitions
      |> Enum.find(fn t ->
        t.condition == nil or t.condition == intent
      end)

    case transition do
      nil ->
        {:ok, ctx, ["I didn't understand. Could you try again?"]}

      %{target: target} ->
        enter_node(ctx, flow, target)
    end
  end

  defp resolve_flow_from_intent(nlu_result) do
    intent = NLU.top_intent(nlu_result)

    if intent do
      # Check if there's a flow whose name matches the intent
      registered = Registry.list()

      case Enum.find(registered, fn name -> name == intent end) do
        nil -> :no_match
        flow_name -> {:ok, flow_name}
      end
    else
      :no_match
    end
  end

  defp interpolate(text, slots) do
    Enum.reduce(slots, text, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)
  end
end
