defmodule Nuvoqs.OliviaEngine.Flow.DSL do
  @moduledoc """
  DSL for defining conversational flows.

  A flow is a directed graph of nodes connected by edges (transitions).
  Each node can require slots to be filled before proceeding.

  ## Example

      defmodule MyApp.Flows.BookFlight do
        use Nuvoqs.OliviaEngine.Flow.DSL

        flow "book_flight" do
          node :greeting do
            say "Where would you like to fly?"
            transition :collect_destination
          end

          node :collect_destination do
            slot :destination, entity: "wit$location", prompt: "What city?"
            slot :date, entity: "wit$datetime", prompt: "When do you want to travel?"
            on_slots_filled :confirm
          end

          node :confirm do
            say "Booking flight to {{destination}} on {{date}}. Confirm?"
            transition :done, when: "confirm"
            transition :collect_destination, when: "deny"
          end

          node :done do
            say "Your flight is booked!"
            action :book_flight
            terminal true
          end
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Nuvoqs.OliviaEngine.Flow.DSL
      Module.register_attribute(__MODULE__, :flows, accumulate: true)
      @before_compile Nuvoqs.OliviaEngine.Flow.DSL
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __flows__, do: @flows
    end
  end

  defmacro flow(name, do: block) do
    quote do
      @current_flow %{name: unquote(name), nodes: %{}, entry_node: nil}
      unquote(block)

      flow_def = %Nuvoqs.OliviaEngine.Flow.Definition{
        name: @current_flow.name,
        nodes: @current_flow.nodes,
        entry_node: @current_flow.entry_node
      }

      @flows flow_def
    end
  end

  defmacro node(name, do: block) do
    quote do
      @current_node %{
        name: unquote(name),
        say: nil,
        slots: [],
        transitions: [],
        on_slots_filled: nil,
        action: nil,
        terminal: false
      }

      if @current_flow.entry_node == nil do
        @current_flow Map.put(@current_flow, :entry_node, unquote(name))
      end

      unquote(block)

      node_def = %Nuvoqs.OliviaEngine.Flow.Node{
        name: @current_node.name,
        say: @current_node.say,
        slots: Enum.reverse(@current_node.slots),
        transitions: Enum.reverse(@current_node.transitions),
        on_slots_filled: @current_node.on_slots_filled,
        action: @current_node.action,
        terminal: @current_node.terminal
      }

      @current_flow Map.update!(@current_flow, :nodes, &Map.put(&1, unquote(name), node_def))
    end
  end

  defmacro say(text) do
    quote do
      @current_node Map.put(@current_node, :say, unquote(text))
    end
  end

  defmacro slot(name, opts) do
    quote do
      slot_def = %Nuvoqs.OliviaEngine.Flow.Slot{
        name: unquote(name),
        entity: Keyword.get(unquote(opts), :entity),
        prompt: Keyword.get(unquote(opts), :prompt),
        required: Keyword.get(unquote(opts), :required, true),
        validator: Keyword.get(unquote(opts), :validator)
      }

      @current_node Map.update!(@current_node, :slots, &[slot_def | &1])
    end
  end

  defmacro transition(target, opts \\ []) do
    quote do
      trans = %Nuvoqs.OliviaEngine.Flow.Transition{
        target: unquote(target),
        condition: Keyword.get(unquote(opts), :when)
      }

      @current_node Map.update!(@current_node, :transitions, &[trans | &1])
    end
  end

  defmacro on_slots_filled(target) do
    quote do
      @current_node Map.put(@current_node, :on_slots_filled, unquote(target))
    end
  end

  defmacro action(name) do
    quote do
      @current_node Map.put(@current_node, :action, unquote(name))
    end
  end

  defmacro terminal(value) do
    quote do
      @current_node Map.put(@current_node, :terminal, unquote(value))
    end
  end
end
