defmodule NuvoqsWeb.MessageController do
  use Phoenix.Controller, formats: [:json]

  alias Nuvoqs.OliviaEngine.Session

  @doc """
  POST /api/sessions/:session_id/messages

  Body: {"text": "I want to book a flight to Paris"}

  Response:
    200: {"responses": ["Where would you like to fly?"], "session_id": "abc123"}
    422: {"error": "text is required"}
  """
  def create(conn, %{"session_id" => session_id} = params) do
    text = params["text"]

    if is_nil(text) or text == "" do
      conn
      |> put_status(422)
      |> json(%{error: "text is required"})
    else
      case Session.send_message(session_id, text) do
        {:ok, responses} ->
          conn
          |> put_status(200)
          |> json(%{
            session_id: session_id,
            responses: responses
          })

        {:error, reason} ->
          conn
          |> put_status(500)
          |> json(%{error: inspect(reason)})
      end
    end
  end
end
