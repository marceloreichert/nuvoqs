defmodule NuvoqsWeb.PoliticBrSenateLive.Form do
  use NuvoqsWeb, :live_view

  alias Nuvoqs.Targets.Politic.Br.Senate.PoliticBrSenatePgFollowerTarget, as: PoliticBrSenateFollowers
  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema, as: PoliticBrSenate

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage politic_br_senate records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="politic_br_senate-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:id]} type="text" label="Id" />
        <.input field={@form[:user_id]} type="text" label="User" />
        <.input field={@form[:politic_br_senate_member_id]} type="text" label="Politic br senate member" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Politic br senate</.button>
          <.button navigate={return_path(@current_scope, @return_to, @politic_br_senate)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    politic_br_senate = PoliticBrSenateFollowers.get_politic_br_senate!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Politic br senate")
    |> assign(:politic_br_senate, politic_br_senate)
    |> assign(:form, to_form(PoliticBrSenateFollowers.change_politic_br_senate(socket.assigns.current_scope, politic_br_senate)))
  end

  defp apply_action(socket, :new, _params) do
    politic_br_senate = %PoliticBrSenate{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Politic br senate")
    |> assign(:politic_br_senate, politic_br_senate)
    |> assign(:form, to_form(PoliticBrSenateFollowers.change_politic_br_senate(socket.assigns.current_scope, politic_br_senate)))
  end

  @impl true
  def handle_event("validate", %{"politic_br_senate" => politic_br_senate_params}, socket) do
    changeset = PoliticBrSenateFollowers.change_politic_br_senate(socket.assigns.current_scope, socket.assigns.politic_br_senate, politic_br_senate_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"politic_br_senate" => politic_br_senate_params}, socket) do
    save_politic_br_senate(socket, socket.assigns.live_action, politic_br_senate_params)
  end

  defp save_politic_br_senate(socket, :edit, politic_br_senate_params) do
    case PoliticBrSenateFollowers.update_politic_br_senate(socket.assigns.current_scope, socket.assigns.politic_br_senate, politic_br_senate_params) do
      {:ok, politic_br_senate} ->
        {:noreply,
         socket
         |> put_flash(:info, "Politic br senate updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, politic_br_senate)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_politic_br_senate(socket, :new, politic_br_senate_params) do
    case PoliticBrSenateFollowers.create_politic_br_senate(socket.assigns.current_scope, politic_br_senate_params) do
      {:ok, politic_br_senate} ->
        {:noreply,
         socket
         |> put_flash(:info, "Politic br senate created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, politic_br_senate)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _politic_br_senate), do: ~p"/politic_br_senate_followers"
  defp return_path(_scope, "show", politic_br_senate), do: ~p"/politic_br_senate_followers/#{politic_br_senate}"
end
