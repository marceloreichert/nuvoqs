defmodule NuvoqsWeb.UserLive.Registration do
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Accounts
  alias Nuvoqs.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />

    <style>
      :root {
        --orange-deep: #b45309;
        --orange-brand: #d97706;
        --orange-bright: #f59e0b;
        --orange-light: #fbbf24;
        --orange-glow: #fcd34d;
        --gold: #f5c542;
        --surface: #1a0f00;
        --text-primary: #fef7ed;
        --text-muted: #c9a76c;
        --code-bg: #1f1409;
        --card-bg: rgba(217, 119, 6, 0.08);
        --card-border: rgba(245, 158, 11, 0.2);
        --teal-accent: #2dd4bf;
      }

      body {
        background: var(--surface);
        color: var(--text-primary);
        font-family: 'Sora', sans-serif;
        min-height: 100vh;
        overflow-x: hidden;
      }

      .reg-bg-grid {
        position: fixed;
        inset: 0;
        z-index: 0;
        background-image:
          linear-gradient(rgba(245, 158, 11, 0.035) 1px, transparent 1px),
          linear-gradient(90deg, rgba(245, 158, 11, 0.035) 1px, transparent 1px);
        background-size: 60px 60px;
      }

      .reg-orb {
        position: fixed;
        border-radius: 50%;
        filter: blur(120px);
        z-index: 0;
        pointer-events: none;
        width: 400px;
        height: 400px;
        background: radial-gradient(circle, rgba(245, 158, 11, 0.15), transparent 70%);
        top: -80px;
        right: -80px;
      }

      .reg-wrapper {
        position: relative;
        z-index: 1;
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 40px 24px;
      }

      .reg-card {
        background: var(--card-bg);
        border: 1px solid var(--card-border);
        border-radius: 20px;
        padding: 48px 40px;
        width: 100%;
        max-width: 420px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        animation: fadeUp 0.7s ease-out both;
      }

      @keyframes fadeUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
      }

      .reg-logo {
        width: 72px;
        height: 72px;
        border-radius: 50%;
        display: block;
        margin: 0 auto 24px;
        box-shadow: 0 0 30px rgba(245, 158, 11, 0.3);
      }

      .reg-title {
        font-size: 1.75rem;
        font-weight: 800;
        letter-spacing: -1px;
        text-align: center;
        margin-bottom: 8px;
        background: linear-gradient(135deg, var(--orange-light), var(--gold));
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
      }

      .reg-subtitle {
        text-align: center;
        color: var(--text-muted);
        font-size: 0.9rem;
        margin-bottom: 32px;
      }

      .reg-subtitle a {
        color: var(--orange-light);
        text-decoration: none;
        font-weight: 600;
      }

      .reg-subtitle a:hover { text-decoration: underline; }

      .reg-card label {
        display: block;
        font-size: 0.85rem;
        font-weight: 600;
        color: var(--text-muted) !important;
        margin-bottom: 6px;
      }

      .reg-card input[type="email"],
      .reg-card input[type="text"] {
        width: 100%;
        background: var(--code-bg) !important;
        border: 1px solid var(--card-border) !important;
        border-radius: 10px !important;
        color: var(--text-primary) !important;
        padding: 12px 16px !important;
        font-size: 0.95rem;
        font-family: 'Sora', sans-serif;
        outline: none;
        transition: border-color 0.2s, box-shadow 0.2s;
        box-shadow: none !important;
      }

      .reg-card input:focus {
        border-color: var(--orange-brand) !important;
        box-shadow: 0 0 0 3px rgba(217, 119, 6, 0.15) !important;
      }

      .reg-card [phx-feedback-for] {
        margin-bottom: 20px;
      }

      .reg-card .phx-no-format { font-family: 'Sora', sans-serif; }

      .reg-submit {
        width: 100%;
        margin-top: 8px;
        background: linear-gradient(135deg, var(--orange-brand), var(--orange-deep));
        color: #fff;
        border: none;
        border-radius: 10px;
        padding: 14px;
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        font-family: 'Sora', sans-serif;
        transition: transform 0.2s, box-shadow 0.3s;
        box-shadow: 0 4px 20px rgba(245, 158, 11, 0.3);
      }

      .reg-submit:hover {
        transform: translateY(-1px);
        box-shadow: 0 6px 30px rgba(245, 158, 11, 0.5);
      }

      .reg-back {
        display: block;
        text-align: center;
        margin-top: 20px;
        color: var(--text-muted);
        font-size: 0.85rem;
        text-decoration: none;
      }

      .reg-back:hover { color: var(--text-primary); }
    </style>

    <div class="reg-bg-grid"></div>
    <div class="reg-orb"></div>

    <div class="reg-wrapper">
      <div class="reg-card">
        <img src="/images/A_Nova_Voz.png" alt="NuvoQS" class="reg-logo" />
        <h1 class="reg-title">Criar conta</h1>
        <p class="reg-subtitle">
          Já tem uma conta?
          <.link navigate={~p"/users/log-in"}>Entrar</.link>
        </p>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />

          <button type="submit" class="reg-submit" phx-disable-with="Criando conta...">
            Criar conta
          </button>
        </.form>

        <.link navigate={~p"/"} class="reg-back">← Voltar ao início</.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: NuvoqsWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
