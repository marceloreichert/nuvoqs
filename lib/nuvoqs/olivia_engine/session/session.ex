defmodule Nuvoqs.OliviaEngine.Session do
  @moduledoc """
  GenServer representing a single user conversation session.

  Each session:
  - Lives as an isolated OTP process
  - Maintains its own dialog context (current flow, node, slots)
  - Auto-terminates after inactivity (default: 30 min)
  - Survives crashes via DynamicSupervisor restart
  """

  use GenServer, restart: :transient

  alias Nuvoqs.OliviaEngine.NLU
  alias Nuvoqs.OliviaEngine.Flow.Engine

  require Logger

  @timeout_ms 30 * 60 * 1000

  defstruct [
    :session_id,
    :context,
    :created_at,
    :last_active_at,
    :message_count
  ]

  # --- Public API ---

  @doc "Start a new session process."
  def start_link(session_id) do
    GenServer.start_link(__MODULE__, session_id, name: via(session_id))
  end

  @doc "Send a user message to a session and get bot responses."
  @spec send_message(String.t(), String.t(), String.t() | nil) :: {:ok, [String.t()]} | {:error, term()}
  def send_message(session_id, text, context \\ nil) do
    case ensure_session(session_id) do
      {:ok, _pid} ->
        GenServer.call(via(session_id), {:message, text, context}, 60_000)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Get the current state of a session."
  @spec get_state(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_state(session_id) do
    case Registry.lookup(Nuvoqs.OliviaEngine.SessionRegistry, session_id) do
      [{_pid, _}] -> GenServer.call(via(session_id), :get_state)
      [] -> {:error, :not_found}
    end
  end

  @doc "Manually start a specific flow in a session."
  @spec start_flow(String.t(), String.t(), String.t() | nil) :: {:ok, [String.t()]} | {:error, term()}
  def start_flow(session_id, flow_name, context \\ nil) do
    case ensure_session(session_id) do
      {:ok, _pid} ->
        GenServer.call(via(session_id), {:start_flow, flow_name, context}, 60_000)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Send a pre-classified intent directly to the engine, bypassing NLU."
  @spec send_intent(String.t(), String.t(), String.t() | nil) :: {:ok, [tuple()]} | {:error, term()}
  def send_intent(session_id, intent, context \\ nil) do
    case ensure_session(session_id) do
      {:ok, _pid} ->
        GenServer.call(via(session_id), {:intent, intent, context}, 60_000)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Reset a session's dialog context."
  @spec reset(String.t()) :: :ok | {:error, :not_found}
  def reset(session_id) do
    case Registry.lookup(Nuvoqs.OliviaEngine.SessionRegistry, session_id) do
      [{_pid, _}] -> GenServer.call(via(session_id), :reset)
      [] -> {:error, :not_found}
    end
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(session_id) do
    Logger.info("Session started: #{session_id}")
    now = DateTime.utc_now()

    context = Engine.new_context() |> Map.put(:metadata, %{user_id: session_id})

    state = %__MODULE__{
      session_id: session_id,
      context: context,
      created_at: now,
      last_active_at: now,
      message_count: 0
    }

    {:ok, state, @timeout_ms}
  end

  @impl true
  def handle_call({:message, text, context}, _from, state) do
    ctx = put_in(state.context, [:metadata, :chat_context], context)

    case NLU.parse(text, context) do
      {:ok, nlu_result} ->
        Logger.info("NLU parse succeeded for session #{state.session_id}: #{inspect(nlu_result)}")
        # 2. Process through flow engine
        case Engine.process_message(ctx, nlu_result) do
          {:ok, new_ctx, responses} ->
            state = %{
              state
              | context: new_ctx,
                last_active_at: DateTime.utc_now(),
                message_count: state.message_count + 1
            }

            {:reply, {:ok, responses}, state, @timeout_ms}

          {:error, reason} ->
            {:reply, {:error, reason}, state, @timeout_ms}
        end

      {:error, reason} ->
        Logger.error("NLU parse failed for session #{state.session_id}: #{inspect(reason)}")

        {:reply, {:ok, [{"Tive um problema ao processar sua mensagem. Tente novamente.", %{}}]},
         %{state | context: ctx}, @timeout_ms}
    end
  end

  @impl true
  def handle_call({:start_flow, flow_name, context}, _from, state) do
    ctx =
      if context,
        do: put_in(state.context, [:metadata, :chat_context], context),
        else: state.context

    case Engine.start_flow(ctx, flow_name) do
      {:ok, new_ctx, responses} ->
        state = %{state | context: new_ctx, last_active_at: DateTime.utc_now()}
        {:reply, {:ok, responses}, state, @timeout_ms}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @timeout_ms}
    end
  end

  @impl true
  def handle_call({:intent, intent, context}, _from, state) do
    ctx =
      if context,
        do: put_in(state.context, [:metadata, :chat_context], context),
        else: state.context

    nlu_result = %Nuvoqs.OliviaEngine.NLU.BumblebeeNLU{
      text: intent,
      intents: [%{name: intent, confidence: 1.0}],
      entities: [],
      traits: %{}
    }

    case Engine.process_message(ctx, nlu_result) do
      {:ok, new_ctx, responses} ->
        state = %{state | context: new_ctx, last_active_at: DateTime.utc_now()}
        {:reply, {:ok, responses}, state, @timeout_ms}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @timeout_ms}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    info = %{
      session_id: state.session_id,
      flow_name: state.context.flow_name,
      current_node: state.context.current_node,
      slots: state.context.slots,
      message_count: state.message_count,
      created_at: state.created_at,
      last_active_at: state.last_active_at
    }

    {:reply, {:ok, info}, state, @timeout_ms}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    state = %{state | context: Engine.new_context()}
    {:reply, :ok, state, @timeout_ms}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("Session #{state.session_id} timed out after inactivity")
    {:stop, :normal, state}
  end

  # --- Helpers ---

  defp via(session_id) do
    {:via, Registry, {Nuvoqs.OliviaEngine.SessionRegistry, session_id}}
  end

  defp ensure_session(session_id) do
    case Registry.lookup(Nuvoqs.OliviaEngine.SessionRegistry, session_id) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        DynamicSupervisor.start_child(
          Nuvoqs.OliviaEngine.SessionSupervisor,
          {__MODULE__, session_id}
        )
    end
  end
end
