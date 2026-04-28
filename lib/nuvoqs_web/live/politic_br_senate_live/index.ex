defmodule NuvoqsWeb.PoliticBrSenateLive.Index do
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Targets.Politic.Br.Senate.PoliticBrSenatePgFollowerTarget, as: PoliticBrSenateFollowers
  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Politic br senate followers
        <:actions>
          <.button variant="primary" navigate={~p"/politic_br_senate_followers/new"}>
            <.icon name="hero-plus" /> New Politic br senate
          </.button>
        </:actions>
      </.header>

      <.table
        id="politic_br_senate_followers"
        rows={@streams.politic_br_senate_followers}
        row_click={fn {_id, politic_br_senate} -> JS.navigate(~p"/politic_br_senate_followers/#{politic_br_senate}") end}
      >
        <:col :let={{_id, politic_br_senate}} label="Id">{politic_br_senate.id}</:col>
        <:col :let={{_id, politic_br_senate}} label="User">{politic_br_senate.user_id}</:col>
        <:col :let={{_id, politic_br_senate}} label="Politic br senate member">{politic_br_senate.politic_br_senate_member_id}</:col>
        <:action :let={{_id, politic_br_senate}}>
          <div class="sr-only">
            <.link navigate={~p"/politic_br_senate_followers/#{politic_br_senate}"}>Show</.link>
          </div>
          <.link navigate={~p"/politic_br_senate_followers/#{politic_br_senate}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, politic_br_senate}}>
          <.link
            phx-click={JS.push("delete", value: %{id: politic_br_senate.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PoliticBrSenateFollowers.subscribe_politic_br_senate_followers(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Politic br senate followers")
     |> stream(:politic_br_senate_followers, list_politic_br_senate_followers(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    politic_br_senate = PoliticBrSenateFollowers.get_politic_br_senate!(socket.assigns.current_scope, id)
    {:ok, _} = PoliticBrSenateFollowers.delete_politic_br_senate(socket.assigns.current_scope, politic_br_senate)

    {:noreply, stream_delete(socket, :politic_br_senate_followers, politic_br_senate)}
  end

  @impl true
  def handle_info({type, %PoliticBrSenateFollowerSchema{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :politic_br_senate_followers, list_politic_br_senate_followers(socket.assigns.current_scope), reset: true)}
  end

  defp list_politic_br_senate_followers(current_scope) do
    PoliticBrSenateFollowers.list_politic_br_senate_followers(current_scope)
  end
end
