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
  alias Nuvoqs.OliviaEngine.NLU.IntentPhrases

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
    %{flow_name: nil, current_node: nil, slots: %{}, history: [], metadata: %{}}
  end

  @doc "Resets flow state but preserves metadata (e.g. user_id)."
  @spec reset_context(context()) :: context()
  def reset_context(ctx) do
    %{new_context() | metadata: ctx.metadata}
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
    case resolve_flow_from_intent(nlu_result) do
      {:ok, flow_name} ->
        start_flow(ctx, flow_name)

      :no_match ->
        suggestions = IntentPhrases.suggestions_for_context(ctx.metadata[:chat_context])
        {:ok, ctx, [{"Não entendi. Pode tentar de outra forma?", %{suggestions: suggestions}}]}
    end
  end

  def process_message(%{flow_name: flow_name, current_node: node_name} = ctx, nlu_result) do
    case Registry.lookup(flow_name) do
      {:ok, flow} ->
        intent = NLU.top_intent(nlu_result)

        if intent in ["cancel", "goodbye"] do
          {:ok, reset_context(ctx), [{"Ok! Se precisar de mais alguma coisa, é só chamar.", %{}}]}
        else
          node = Map.fetch!(flow.nodes, node_name)
          {ctx, slot_errors} = fill_slots_from_nlu(ctx, node, nlu_result)

          cond do
            has_unfilled_required_slots?(node, ctx.slots) ->
              prompt = next_slot_prompt(node, ctx.slots)
              error_tuples = slot_errors |> Map.values() |> Enum.map(&{&1, %{}})
              {:ok, ctx, error_tuples ++ [{prompt, %{}}]}

            node.on_slots_filled != nil ->
              ctx = %{ctx | history: [node_name | ctx.history]}
              enter_node(ctx, flow, node.on_slots_filled)

            true ->
              evaluate_transitions(ctx, flow, node, nlu_result)
          end
        end

      :not_found ->
        {:error, :flow_not_found}
    end
  end

  # --- Private ---

  defp enter_node(ctx, flow, node_name) do
    node = Map.fetch!(flow.nodes, node_name)
    ctx = %{ctx | current_node: node_name, history: [node_name | ctx.history]}

    case run_action(node.action, ctx) do
      {:halt, msg} ->
        {:ok, reset_context(ctx), [{msg, %{}}]}

      action_responses ->
        responses =
          case node.say do
            nil  -> action_responses
            text -> action_responses ++ [{interpolate(text, ctx.slots), %{}}]
          end

        if node.terminal do
          {:ok, reset_context(ctx), responses}
        else
          if node.slots != [] and has_unfilled_required_slots?(node, ctx.slots) do
            prompt = next_slot_prompt(node, ctx.slots)
            {:ok, ctx, responses ++ [{prompt, %{}}]}
          else
            {:ok, ctx, responses}
          end
        end
    end
  end

  defp run_action(nil, _ctx), do: []
  defp run_action(action_name, ctx) do
    case Nuvoqs.OliviaEngine.Flow.Actions.execute(action_name, ctx) do
      {:halt, msg}           -> {:halt, msg}
      {:ok, :multi, entries} -> entries
      {:ok, msg, meta}       -> [{msg, meta}]
      {:ok, msg}             -> [{msg, %{}}]
      _                      -> []
    end
  end

  defp fill_slots_from_nlu(ctx, node, nlu_result) do
    raw_text = String.trim(nlu_result.text)

    {filled, errors} =
      node.slots
      |> Enum.reduce({ctx.slots, %{}}, fn slot, {slots_acc, errors_acc} ->
        if Map.has_key?(slots_acc, slot.name) do
          {slots_acc, errors_acc}
        else
          candidate =
            if slot.entity do
              NLU.get_entity(nlu_result, slot.entity) ||
                if raw_text != "", do: raw_text, else: nil
            else
              if raw_text != "", do: raw_text, else: nil
            end

          case {candidate, slot.validator} do
            {nil, _} ->
              {slots_acc, errors_acc}

            {value, nil} ->
              {Map.put(slots_acc, slot.name, value), errors_acc}

            {value, validator} ->
              case Nuvoqs.OliviaEngine.Flow.Actions.validate(validator, value) do
                {:ok, canonical} ->
                  {Map.put(slots_acc, slot.name, canonical), errors_acc}

                {:ok, canonical, extra} ->
                  merged = slots_acc |> Map.put(slot.name, canonical) |> Map.merge(extra)
                  {merged, errors_acc}

                {:error, msg} ->
                  {slots_acc, Map.put(errors_acc, slot.name, msg)}
              end
          end
        end
      end)

    {%{ctx | slots: filled}, errors}
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
      nil -> "Continue..."
      slot -> slot.prompt || "Por favor, informe #{slot.name}."
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
        case resolve_flow_from_intent(nlu_result) do
          {:ok, new_flow_name} when new_flow_name != flow.name ->
            start_flow(reset_context(ctx), new_flow_name)

          _ ->
            suggestions = IntentPhrases.suggestions_for_context(ctx.metadata[:chat_context])
            {:ok, ctx, [{"Não entendi. Pode tentar de outra forma?", %{suggestions: suggestions}}]}
        end

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
