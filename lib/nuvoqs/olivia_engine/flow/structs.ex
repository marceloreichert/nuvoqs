defmodule Nuvoqs.OliviaEngine.Flow.Definition do
  @moduledoc "A complete flow definition with nodes and entry point."
  defstruct [:name, :nodes, :entry_node]

  @type t :: %__MODULE__{
          name: String.t(),
          nodes: %{atom() => Nuvoqs.OliviaEngine.Flow.Node.t()},
          entry_node: atom()
        }
end

defmodule Nuvoqs.OliviaEngine.Flow.Node do
  @moduledoc "A single node in a dialog flow."
  defstruct [:name, :say, :slots, :transitions, :on_slots_filled, :action, :terminal]

  @type t :: %__MODULE__{
          name: atom(),
          say: String.t() | nil,
          slots: [Nuvoqs.OliviaEngine.Flow.Slot.t()],
          transitions: [Nuvoqs.OliviaEngine.Flow.Transition.t()],
          on_slots_filled: atom() | nil,
          action: atom() | nil,
          terminal: boolean()
        }
end

defmodule Nuvoqs.OliviaEngine.Flow.Slot do
  @moduledoc "A slot (entity) that needs to be filled in a dialog node."
  defstruct [:name, :entity, :prompt, :required, :validator]

  @type t :: %__MODULE__{
          name: atom(),
          entity: String.t() | nil,
          prompt: String.t() | nil,
          required: boolean(),
          validator: (any() -> boolean()) | nil
        }
end

defmodule Nuvoqs.OliviaEngine.Flow.Transition do
  @moduledoc "An edge between two nodes, optionally conditioned on an intent."
  defstruct [:target, :condition]

  @type t :: %__MODULE__{
          target: atom(),
          condition: String.t() | nil
        }
end
