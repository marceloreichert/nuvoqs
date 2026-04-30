defmodule NuvoqsWeb.SessionController do
  use Phoenix.Controller, formats: [:json]

  alias Nuvoqs.OliviaEngine.Session

  @doc "GET /api/sessions/:session_id"
  def show(conn, %{"session_id" => session_id}) do
    case Session.get_state(session_id) do
      {:ok, state} ->
        json(conn, %{session: state})

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "session not found"})
    end
  end

  @doc "POST /api/sessions/:session_id/flows/:flow_name"
  def start_flow(conn, %{"session_id" => session_id, "flow_name" => flow_name}) do
    case Session.start_flow(session_id, flow_name) do
      {:ok, responses} ->
        json(conn, %{session_id: session_id, responses: responses})

      {:error, :flow_not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "flow '#{flow_name}' not found"})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc "DELETE /api/sessions/:session_id"
  def reset(conn, %{"session_id" => session_id}) do
    case Session.reset(session_id) do
      :ok ->
        json(conn, %{ok: true})

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "session not found"})
    end
  end
end
