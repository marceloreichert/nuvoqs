defmodule Nuvoqs.Behaviours.EventBehaviour do
  @callback process_event() :: :ok
  @callback interval_ms() :: integer()

  defstruct [:module]

  def start_link(module) do
    GenServer.start_link(__MODULE__, module, name: module)
  end

  def init(module) do
    Process.flag(:trap_exit, true)

    client = %__MODULE__{
      module: module
    }

    {:ok, client, {:continue, :connect}}
  end

  def handle_continue(:connect, client) do
    Process.send_after(self(), :tick, 1_000)

    {:noreply, client}
  end

  def handle_info(:tick, client) do
    process_tick(client.module)

    Process.send_after(self(), :tick, interval_ms(client.module))

    {:noreply, client}
  end

  defp process_tick(module), do: module.process_event()
  defp interval_ms(module), do: module.interval_ms()
end
