defmodule Nuvoqs.OliviaEngine.Flow.Actions do
  @moduledoc """
  Registry and executor for flow actions.

  Actions are side-effects triggered when a flow node is entered.
  Register custom actions at runtime or define them in your app.

  ## Example

      Nuvoqs.OliviaEngine.Flow.Actions.register(:book_flight, fn ctx ->
        destination = ctx.slots[:destination]
        date = ctx.slots[:date]
        # ... call booking API ...
        {:ok, "Flight booked to \#{destination} on \#{date}!"}
      end)
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Register an action handler function."
  @spec register(atom(), (map() -> {:ok, String.t()} | :ok | {:error, term()})) :: :ok
  def register(name, handler) when is_atom(name) and is_function(handler, 1) do
    GenServer.call(__MODULE__, {:register, name, handler})
  end

  @doc "Execute a registered action with the current dialog context."
  @spec execute(atom(), map()) :: {:ok, String.t()} | :ok | {:error, term()}
  def execute(name, ctx) do
    case GenServer.call(__MODULE__, {:lookup, name}) do
      {:ok, handler} ->
        try do
          handler.(ctx)
        rescue
          e ->
            require Logger
            Logger.error("Action #{name} failed: #{inspect(e)}")
            {:error, :action_failed}
        end

      :not_found ->
        require Logger
        Logger.warning("Action #{name} not registered")
        :ok
    end
  end

  @doc "Register a slot validator. Handler: fn(value) -> {:ok, canonical} | {:error, message}"
  @spec register_validator(atom(), (String.t() -> {:ok, String.t()} | {:error, String.t()})) :: :ok
  def register_validator(name, handler) when is_atom(name) and is_function(handler, 1) do
    GenServer.call(__MODULE__, {:register_validator, name, handler})
  end

  @doc """
  Run a registered validator.
  Returns:
    {:ok, canonical}              – valid, use canonical as slot value
    {:ok, canonical, extra_slots} – valid + fill additional slots (map)
    {:error, message}             – invalid, keep slot empty
  """
  @spec validate(atom(), String.t()) ::
          {:ok, String.t()} | {:ok, String.t(), map()} | {:error, String.t()}
  def validate(name, value) do
    case GenServer.call(__MODULE__, {:lookup_validator, name}) do
      {:ok, handler} ->
        try do
          handler.(value)
        rescue
          e ->
            require Logger
            Logger.error("Validator #{name} failed: #{inspect(e)}")
            {:ok, value}
        end

      :not_found ->
        {:ok, value}
    end
  end

  # GenServer

  @impl true
  def init(_) do
    {:ok, %{actions: %{}, validators: %{}}}
  end

  @impl true
  def handle_call({:register, name, handler}, _from, state) do
    {:reply, :ok, put_in(state, [:actions, name], handler)}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    case Map.fetch(state.actions, name) do
      {:ok, handler} -> {:reply, {:ok, handler}, state}
      :error -> {:reply, :not_found, state}
    end
  end

  @impl true
  def handle_call({:register_validator, name, handler}, _from, state) do
    {:reply, :ok, put_in(state, [:validators, name], handler)}
  end

  @impl true
  def handle_call({:lookup_validator, name}, _from, state) do
    case Map.fetch(state.validators, name) do
      {:ok, handler} -> {:reply, {:ok, handler}, state}
      :error -> {:reply, :not_found, state}
    end
  end
end
