defmodule NuvoqsWeb.UserLive.Login do
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Accounts

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
        --gold: #f5c542;
        --surface: #1a0f00;
        --text-primary: #fef7ed;
        --text-muted: #c9a76c;
        --code-bg: #1f1409;
        --card-bg: rgba(217, 119, 6, 0.08);
        --card-border: rgba(245, 158, 11, 0.2);
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
        max-width: 440px;
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
        margin-bottom: 28px;
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
      .reg-card input[type="text"],
      .reg-card input[type="password"] {
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

      .reg-card [phx-feedback-for] { margin-bottom: 16px; }

      .reg-submit {
        width: 100%;
        margin-top: 4px;
        background: linear-gradient(135deg, var(--orange-brand), var(--orange-deep));
        color: #fff;
        border: none;
        border-radius: 10px;
        padding: 13px;
        font-size: 0.95rem;
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

      .reg-submit-soft {
        width: 100%;
        margin-top: 8px;
        background: rgba(217, 119, 6, 0.1);
        color: var(--orange-light);
        border: 1px solid var(--card-border);
        border-radius: 10px;
        padding: 13px;
        font-size: 0.95rem;
        font-weight: 600;
        cursor: pointer;
        font-family: 'Sora', sans-serif;
        transition: background 0.2s, border-color 0.2s;
      }

      .reg-submit-soft:hover {
        background: rgba(217, 119, 6, 0.2);
        border-color: var(--orange-bright);
      }

      .login-divider {
        display: flex;
        align-items: center;
        gap: 12px;
        margin: 24px 0;
        color: var(--text-muted);
        font-size: 0.82rem;
      }

      .login-divider::before,
      .login-divider::after {
        content: '';
        flex: 1;
        height: 1px;
        background: var(--card-border);
      }

      .login-alert {
        background: rgba(45, 212, 191, 0.08);
        border: 1px solid rgba(45, 212, 191, 0.2);
        border-radius: 10px;
        padding: 14px 16px;
        font-size: 0.85rem;
        color: #5eead4;
        margin-bottom: 20px;
        line-height: 1.5;
      }

      .login-alert a {
        color: #2dd4bf;
        text-decoration: underline;
      }

      .reg-back {
        display: block;
        text-align: center;
        margin-top: 24px;
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
        <h1 class="reg-title">Entrar</h1>
        <p class="reg-subtitle">
          <%= if @current_scope do %>
            Confirme sua identidade para continuar.
          <% else %>
            Não tem uma conta?
            <.link navigate={~p"/users/register"}>Criar conta</.link>
          <% end %>
        </p>

        <div :if={local_mail_adapter?()} class="login-alert">
          Você está usando o adaptador de e-mail local.
          Veja os e-mails enviados em
          <.link href="/dev/mailbox">Mailbox</.link>.
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <button type="submit" class="reg-submit">
            Entrar com link por e-mail →
          </button>
        </.form>

        <div class="login-divider">ou</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Senha"
            autocomplete="current-password"
            spellcheck="false"
          />
          <button
            type="submit"
            class="reg-submit"
            name={@form[:remember_me].name}
            value="true"
          >
            Entrar e permanecer logado →
          </button>
          <button type="submit" class="reg-submit-soft">
            Entrar apenas desta vez
          </button>
        </.form>

        <.link navigate={~p"/"} class="reg-back">← Voltar ao início</.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:nuvoqs, Nuvoqs.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
