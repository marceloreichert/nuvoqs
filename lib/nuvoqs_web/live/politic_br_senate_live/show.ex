defmodule NuvoqsWeb.PoliticBrSenateLive.Show do
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Targets.Politic.Br.Senate.PoliticBrSenatePgFollowerTarget, as: PoliticBrSenateFollowers
  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Politic br senate {@politic_br_senate.id}
        <:subtitle>This is a politic_br_senate record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/politic_br_senate_followers"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/politic_br_senate_followers/#{@politic_br_senate}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit politic_br_senate
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@politic_br_senate.id}</:item>
        <:item title="User">{@politic_br_senate.user_id}</:item>
        <:item title="Politic br senate member">{@politic_br_senate.politic_br_senate_member_id}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      PoliticBrSenateFollowers.subscribe_politic_br_senate_followers(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Politic br senate")
     |> assign(:politic_br_senate, PoliticBrSenateFollowers.get_politic_br_senate!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %PoliticBrSenateFollowerSchema{id: id} = politic_br_senate},
        %{assigns: %{politic_br_senate: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :politic_br_senate, politic_br_senate)}
  end

  def handle_info(
        {:deleted, %PoliticBrSenateFollowerSchema{id: id}},
        %{assigns: %{politic_br_senate: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current politic_br_senate was deleted.")
     |> push_navigate(to: ~p"/politic_br_senate_followers")}
  end

  def handle_info({type, %PoliticBrSenateFollowerSchema{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
