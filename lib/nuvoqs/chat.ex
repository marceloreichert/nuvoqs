defmodule Nuvoqs.Chat do
  @moduledoc false

  import Ecto.Query
  alias Nuvoqs.Repo
  alias Nuvoqs.Schemas.Chat.MessageSchema

  def list_messages(room \\ "general", limit \\ 50) do
    MessageSchema
    |> where([m], m.room == ^room)
    |> order_by([m], asc: m.inserted_at)
    |> limit(^limit)
    |> preload(:sender)
    |> Repo.all()
  end

  def create_message(attrs) do
    with {:ok, message} <-
           %MessageSchema{}
           |> MessageSchema.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(message, :sender)}
    end
  end

  def bot_message(content, opts \\ []) do
    %{
      id: Ecto.UUID.generate(),
      content: content,
      room: Keyword.get(opts, :room, "general"),
      sender_id: nil,
      sender: %{email: "olivia@nuvoqs.ai"},
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      image_url: Keyword.get(opts, :image_url),
      suggestions: Keyword.get(opts, :suggestions, []),
      bot: true
    }
  end
end
