defmodule NuvoqsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use NuvoqsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :current_scope, :map, default: nil

  def main_nav(assigns) do
    ~H"""
    <nav style="padding: 16px 24px; display: flex; align-items: center; justify-content: space-between; background: rgba(26, 15, 0, 0.95); border-bottom: 1px solid rgba(245, 158, 11, 0.2); backdrop-filter: blur(8px); position: relative; z-index: 10;">
      <a href={~p"/"} style="display: flex; align-items: center; gap: 14px; text-decoration: none;">
        <img
          src="/images/A_Nova_Voz.png"
          alt="nuvoqs"
          style="width: 42px; height: 42px; border-radius: 50%; object-fit: cover; box-shadow: 0 0 24px rgba(245, 158, 11, 0.35);"
        />
        <div style="display: flex; flex-direction: column; line-height: 1.2;">
          <span style="font-weight: 700; font-size: 1.05rem; letter-spacing: -0.3px; color: #fef7ed;">
            nuvoqs
          </span>
          <span style="font-size: 0.65rem; color: #c9a76c; font-weight: 400; letter-spacing: 0.5px; text-transform: uppercase;">
            Dados Abertos para os Cidadãos
          </span>
        </div>
      </a>
      <ul style="display: flex; gap: 28px; list-style: none; align-items: center; margin: 0; padding: 0;">
        <%= if @current_scope do %>
          <li style="font-size: 0.85rem; color: #c9a76c;">{@current_scope.user.email}</li>
          <li>
            <.link
              href={~p"/users/settings"}
              style="color: #c9a76c; text-decoration: none; font-size: 0.9rem;"
            >
              Settings
            </.link>
          </li>
          <li>
            <.link
              href={~p"/users/log-out"}
              method="delete"
              style="color: #c9a76c; text-decoration: none; font-size: 0.9rem;"
            >
              Log out
            </.link>
          </li>
        <% else %>
          <li>
            <.link
              href={~p"/users/register"}
              style="background: #d97706; color: #1a0f00; padding: 8px 20px; border-radius: 8px; font-weight: 600; text-decoration: none; font-size: 0.9rem;"
            >
              Register
            </.link>
          </li>
          <li>
            <.link
              href={~p"/users/log-in"}
              style="background: #d97706; color: #1a0f00; padding: 8px 20px; border-radius: 8px; font-weight: 600; text-decoration: none; font-size: 0.9rem;"
            >
              Log in
            </.link>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
