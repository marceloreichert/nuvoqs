defmodule NuvoqsWeb.ChatLive do
  require Logger
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Chat
  alias NuvoqsWeb.Layouts
  alias Nuvoqs.OliviaEngine.NLU.IntentPhrases

  @topic "chat:general"
  @intent_only ~w[confirm deny]

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      :root {
        --orange-deep: #b45309;
        --orange-brand: #d97706;
        --orange-bright: #f59e0b;
        --orange-light: #fbbf24;
        --gold: #f5c542;
        --surface: #1a0f00;
        --text-primary: #fef7ed;
        --text-muted: #c9a76c;
        --code-bg: #1f1409;
        --card-bg: rgba(217, 119, 6, 0.08);
        --card-border: rgba(245, 158, 11, 0.2);
        --teal-accent: #2dd4bf;
      }

      html, body {
        height: 100%;
        margin: 0;
        overflow: hidden;
        background: var(--surface);
        color: var(--text-primary);
        font-family: 'Sora', sans-serif;
      }

      [data-phx-main] {
        height: 100%;
        display: flex;
        flex-direction: column;
      }

      .chat-page {
        display: flex;
        flex-direction: column;
        height: 100%;
        min-height: 0;
      }

      .chat-wrapper {
        display: flex;
        flex-direction: column;
        flex: 1;
        min-height: 0;
      }

      .chat-layout {
        display: flex;
        flex-direction: column;
        flex: 1;
        min-height: 0;
      }

      .chat-header {
        display: flex;
        align-items: center;
        gap: 14px;
        padding: 14px 20px;
        background: rgba(26, 15, 0, 0.95);
        border-bottom: 1px solid var(--card-border);
        backdrop-filter: blur(8px);
        z-index: 10;
        flex-shrink: 0;
      }

      .chat-header-avatar {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        object-fit: cover;
        box-shadow: 0 0 16px rgba(245, 158, 11, 0.3);
      }

      .chat-header-info { flex: 1; }

      .chat-header-name {
        font-weight: 700;
        font-size: 1rem;
        color: var(--text-primary);
        letter-spacing: -0.3px;
      }

      .chat-header-status {
        font-size: 0.75rem;
        color: var(--teal-accent);
        display: flex;
        align-items: center;
        gap: 5px;
      }

      .chat-header-status::before {
        content: '';
        width: 6px;
        height: 6px;
        background: var(--teal-accent);
        border-radius: 50%;
        animation: pulse-dot 2s infinite;
      }

      @keyframes pulse-dot {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.4; }
      }

      .chat-header-back {
        color: var(--text-muted);
        text-decoration: none;
        font-size: 0.85rem;
        display: flex;
        align-items: center;
        gap: 4px;
        transition: color 0.2s;
      }

      .chat-header-back:hover { color: var(--text-primary); }

      .chat-messages {
        flex: 1;
        overflow-y: auto;
        padding: 20px 16px;
        display: flex;
        flex-direction: column;
        gap: 6px;
        scrollbar-width: thin;
        scrollbar-color: var(--card-border) transparent;
      }

      .chat-messages::-webkit-scrollbar { width: 4px; }
      .chat-messages::-webkit-scrollbar-thumb {
        background: var(--card-border);
        border-radius: 4px;
      }

      .chat-day-separator {
        text-align: center;
        margin: 12px 0;
        color: var(--text-muted);
        font-size: 0.75rem;
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .chat-day-separator::before,
      .chat-day-separator::after {
        content: '';
        flex: 1;
        height: 1px;
        background: var(--card-border);
      }

      .msg-row {
        display: flex;
        align-items: flex-end;
        gap: 8px;
        max-width: 75%;
        animation: msgIn 0.2s ease-out both;
      }

      @keyframes msgIn {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
      }

      .msg-row.sent {
        align-self: flex-end;
        flex-direction: row-reverse;
      }

      .msg-row.received { align-self: flex-start; }

      .msg-avatar {
        width: 28px;
        height: 28px;
        border-radius: 50%;
        background: var(--card-bg);
        border: 1px solid var(--card-border);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.65rem;
        font-weight: 700;
        color: var(--orange-light);
        flex-shrink: 0;
      }

      .msg-bubble {
        padding: 10px 14px;
        border-radius: 18px;
        font-size: 0.9rem;
        line-height: 1.45;
        word-break: break-word;
        position: relative;
      }

      .msg-row.sent .msg-bubble {
        background: linear-gradient(135deg, var(--orange-brand), var(--orange-deep));
        color: #fff;
        border-bottom-right-radius: 4px;
        box-shadow: 0 2px 12px rgba(217, 119, 6, 0.3);
      }

      .msg-row.received .msg-bubble {
        background: var(--card-bg);
        border: 1px solid var(--card-border);
        color: var(--text-primary);
        border-bottom-left-radius: 4px;
      }

      .msg-meta {
        font-size: 0.68rem;
        margin-top: 4px;
        opacity: 0.6;
        text-align: right;
      }

      .msg-row.received .msg-meta { text-align: left; }

      .chat-input-area {
        padding: 12px 16px;
        background: rgba(26, 15, 0, 0.95);
        border-top: 1px solid var(--card-border);
        backdrop-filter: blur(8px);
        flex-shrink: 0;
      }

      .chat-input-form {
        display: flex;
        align-items: flex-end;
        gap: 10px;
        max-width: 860px;
        margin: 0 auto;
      }

      .chat-input-wrap {
        flex: 1;
        background: var(--code-bg);
        border: 1px solid var(--card-border);
        border-radius: 24px;
        display: flex;
        align-items: flex-end;
        padding: 8px 16px;
        transition: border-color 0.2s;
      }

      .chat-input-wrap:focus-within {
        border-color: var(--orange-brand);
        box-shadow: 0 0 0 3px rgba(217, 119, 6, 0.12);
      }

      .chat-input {
        flex: 1;
        background: transparent;
        border: none;
        outline: none;
        color: var(--text-primary);
        font-size: 0.95rem;
        font-family: 'Sora', sans-serif;
        resize: none;
        max-height: 120px;
        line-height: 1.5;
        padding: 0;
      }

      .chat-input::placeholder { color: var(--text-muted); }

      .chat-send-btn {
        width: 44px;
        height: 44px;
        border-radius: 50%;
        background: linear-gradient(135deg, var(--orange-brand), var(--orange-deep));
        border: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: transform 0.2s, box-shadow 0.2s;
        box-shadow: 0 4px 16px rgba(217, 119, 6, 0.35);
        flex-shrink: 0;
      }

      .chat-send-btn:hover {
        transform: scale(1.08);
        box-shadow: 0 6px 24px rgba(217, 119, 6, 0.5);
      }

      .chat-send-btn svg {
        width: 20px;
        height: 20px;
        fill: white;
      }

      .chat-empty {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-muted);
        font-size: 0.9rem;
        flex-direction: column;
        gap: 10px;
        opacity: 0.6;
      }

      .olivia-avatar {
        background: linear-gradient(135deg, var(--orange-brand), var(--orange-deep));
        color: #fff;
        border: none;
        box-shadow: 0 0 12px rgba(217, 119, 6, 0.4);
      }

      .msg-sender-name {
        font-size: 0.72rem;
        color: var(--text-muted);
        margin-bottom: 2px;
        padding-left: 2px;
      }

      .msg-sender-name.olivia-name {
        color: var(--orange-light);
        font-weight: 600;
      }

      .chat-at-hint {
        font-size: 0.75rem;
        color: var(--text-muted);
        text-align: center;
        padding: 4px 0 2px;
        opacity: 0.5;
      }

      .msg-suggestions {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-top: 8px;
      }

      .suggestion-btn {
        background: rgba(217, 119, 6, 0.12);
        border: 1px solid rgba(245, 158, 11, 0.3);
        border-radius: 20px;
        color: var(--orange-light);
        font-size: 0.8rem;
        padding: 5px 12px;
        cursor: pointer;
        font-family: 'Sora', sans-serif;
        transition: background 0.2s, border-color 0.2s;
      }

      .suggestion-btn:hover {
        background: rgba(217, 119, 6, 0.25);
        border-color: rgba(245, 158, 11, 0.6);
      }

      .chat-help-btn {
        background: transparent;
        border: 1px solid rgba(245, 158, 11, 0.35);
        border-radius: 20px;
        color: var(--text-muted);
        font-size: 0.78rem;
        padding: 6px 14px;
        cursor: pointer;
        font-family: 'Sora', sans-serif;
        white-space: nowrap;
        transition: color 0.2s, border-color 0.2s, background 0.2s;
        align-self: flex-end;
        margin-bottom: 2px;
        flex-shrink: 0;
      }

      .chat-help-btn:hover {
        color: var(--orange-light);
        border-color: rgba(245, 158, 11, 0.7);
        background: rgba(217, 119, 6, 0.08);
      }
    </style>

    <div class="chat-page">
    <Layouts.main_nav current_scope={@current_scope} />

    <div class="chat-wrapper">
      <div :if={@chat_context} style="display: flex; align-items: center; gap: 14px; padding: 12px 24px; background: rgba(217, 119, 6, 0.06); border-bottom: 1px solid rgba(245, 158, 11, 0.15); flex-shrink: 0;">
        <img src={@chat_context.icon} style="width: 36px; height: 36px; object-fit: contain; border-radius: 6px;" />
        <div>
          <div style="font-weight: 700; font-size: 1rem; color: #fef7ed;">{@chat_context.title}</div>
          <div style="font-size: 0.75rem; color: #c9a76c;">{@chat_context.subtitle}</div>
        </div>
      </div>

      <div class="chat-layout">

      <div class="chat-messages" id="chat-messages" phx-hook="ScrollBottom">
        <div :if={@messages_empty} class="chat-empty">
          <span>💬</span> Nenhuma mensagem ainda. Seja o primeiro!
        </div>

        <div :for={{dom_id, msg} <- @streams.messages} id={dom_id}>
          <div class={"msg-row #{if msg.sender_id == @current_user_id, do: "sent", else: "received"}"}>
            <div
              :if={msg.sender_id != @current_user_id}
              class={"msg-avatar #{if is_nil(msg.sender_id), do: "olivia-avatar", else: ""}"}
            >
              {if is_nil(msg.sender_id),
                do: "✦",
                else: msg.sender.email |> String.upcase() |> String.first()}
            </div>
            <div>
              <div
                :if={msg.sender_id != @current_user_id}
                class={"msg-sender-name #{if is_nil(msg.sender_id), do: "olivia-name", else: ""}"}
              >
                {if is_nil(msg.sender_id), do: "Olivia", else: msg.sender.email}
              </div>
              <div class="msg-bubble">
                <img
                  :if={Map.get(msg, :image_url)}
                  src={msg.image_url}
                  style={"border-radius: 50%; object-fit: cover; display: block; border: 2px solid rgba(245,158,11,0.3); #{if msg.content == "", do: "width: 96px; height: 96px;", else: "width: 72px; height: 72px; margin-bottom: 8px;"}"}
                />
                {msg.content}
              </div>
              <div :if={Map.get(msg, :suggestions, []) != []} class="msg-suggestions">
                <button
                  :for={{label, flow} <- Map.get(msg, :suggestions, [])}
                  class="suggestion-btn"
                  phx-click="suggest"
                  phx-value-text={label}
                  phx-value-flow={flow}
                  type="button"
                >
                  {label}
                </button>
              </div>
              <div class="msg-meta">
                {Calendar.strftime(msg.inserted_at, "%H:%M")}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="chat-input-area">
        <form class="chat-input-form" phx-submit="send">
          <button
            :if={@context_suggestions != []}
            type="button"
            class="chat-help-btn"
            phx-click="help"
          >
            Preciso de ajuda!
          </button>
          <div class="chat-input-wrap">
            <textarea
              name="content"
              class="chat-input"
              placeholder="Digite uma mensagem..."
              rows="1"
              phx-hook="AutoResize"
              id="chat-input"
            ></textarea>
          </div>
          <button type="submit" class="chat-send-btn" aria-label="Enviar">
            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
              <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
            </svg>
          </button>
        </form>
      </div>
    </div>
    </div>
    </div>
    """
  end

  @contexts %{
    "politic_br_senate" => %{
      title: "Senado Federal",
      subtitle: "Votações e acompanhamento de senadores",
      icon: "/images/senado_federal.png"
    }
  }

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Nuvoqs.PubSub, @topic)
    end

    user = socket.assigns.current_scope.user
    messages = Chat.list_messages()
    context_key = params["context"]
    context = Map.get(@contexts, context_key)

    {:ok,
     socket
     |> assign(:current_user_id, user.id)
     |> assign(:chat_context, context)
     |> assign(:chat_context_key, context_key)
     |> assign(:context_suggestions, IntentPhrases.suggestions_for_context(context_key))
     |> assign(:messages_empty, messages == [])
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("send", %{"content" => content}, socket) do
    content = String.trim(content)

    if content != "" do
      case Chat.create_message(%{
             content: content,
             sender_id: socket.assigns.current_user_id
           }) do
        {:ok, message} ->
          Phoenix.PubSub.broadcast(Nuvoqs.PubSub, @topic, {:new_message, message})
          maybe_invoke_olivia(content, socket.assigns.current_user_id, socket.assigns.chat_context_key)
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("help", _params, socket) do
    suggestions = socket.assigns.context_suggestions

    if suggestions != [] do
      case Chat.create_bot_message("Como posso ajudar? Escolha uma opção:", %{suggestions: suggestions}) do
        {:ok, msg} -> Phoenix.PubSub.broadcast(Nuvoqs.PubSub, @topic, {:new_message, msg})
        _ -> :ok
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("suggest", %{"text" => text, "flow" => flow_name}, socket) do
    if text != "" do
      case Chat.create_message(%{content: text, sender_id: socket.assigns.current_user_id}) do
        {:ok, message} ->
          Phoenix.PubSub.broadcast(Nuvoqs.PubSub, @topic, {:new_message, message})

          if flow_name in @intent_only do
            invoke_olivia_intent(flow_name, socket.assigns.current_user_id, socket.assigns.chat_context_key)
          else
            invoke_olivia_flow(flow_name, socket.assigns.current_user_id, socket.assigns.chat_context_key)
          end

          {:noreply, socket}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply,
     socket
     |> assign(:messages_empty, false)
     |> stream_insert(:messages, message)}
  end

  @impl true
  def handle_info({:bot_messages, messages}, socket) do
    socket =
      Enum.reduce(messages, socket, fn msg, acc ->
        acc
        |> assign(:messages_empty, false)
        |> stream_insert(:messages, msg)
      end)

    {:noreply, socket}
  end

  defp invoke_olivia_intent(intent, user_id, context) do
    session_id = to_string(user_id)
    topic = @topic

    Task.start(fn ->
      case Nuvoqs.OliviaEngine.Session.send_intent(session_id, intent, context) do
        {:ok, responses} ->
          msgs =
            Enum.flat_map(responses, fn {text, meta} ->
              case Chat.create_bot_message(text, meta) do
                {:ok, msg} -> [msg]
                _ -> []
              end
            end)

          if msgs != [] do
            Phoenix.PubSub.broadcast(Nuvoqs.PubSub, topic, {:bot_messages, msgs})
          end

        _ ->
          :ok
      end
    end)
  end

  defp invoke_olivia_flow(flow_name, user_id, context) do
    session_id = to_string(user_id)
    topic = @topic

    Task.start(fn ->
      case Nuvoqs.OliviaEngine.Session.start_flow(session_id, flow_name, context) do
        {:ok, responses} ->
          msgs =
            Enum.flat_map(responses, fn {text, meta} ->
              case Chat.create_bot_message(text, meta) do
                {:ok, msg} -> [msg]
                _ -> []
              end
            end)

          if msgs != [] do
            Phoenix.PubSub.broadcast(Nuvoqs.PubSub, topic, {:bot_messages, msgs})
          end

        _ ->
          :ok
      end
    end)
  end

  defp maybe_invoke_olivia(content, user_id, context) do
    session_id = to_string(user_id)
    topic = @topic

    Task.start(fn ->
      case Nuvoqs.OliviaEngine.Session.send_message(session_id, content, context) do
        {:ok, responses} ->
          Logger.info("Received responses: #{inspect(responses)}")

          msgs =
            Enum.flat_map(responses, fn {text, meta} ->
              case Chat.create_bot_message(text, meta) do
                {:ok, msg} -> [msg]
                _ -> []
              end
            end)

          if msgs != [] do
            Phoenix.PubSub.broadcast(Nuvoqs.PubSub, topic, {:bot_messages, msgs})
          end

        _ ->
          :ok
      end
    end)
  end
end
