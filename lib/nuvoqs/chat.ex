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
    |> Enum.map(&to_message_map/1)
  end

  def create_message(attrs) do
    with {:ok, message} <-
           %MessageSchema{}
           |> MessageSchema.changeset(attrs)
           |> Repo.insert() do
      {:ok, message |> Repo.preload(:sender) |> to_message_map()}
    end
  end

  def create_bot_message(content, meta \\ %{}) do
    with {:ok, message} <-
           %MessageSchema{}
           |> MessageSchema.bot_changeset(%{content: content || "", metadata: stringify_keys(meta)})
           |> Repo.insert() do
      {:ok, to_message_map(message)}
    end
  end

  defp to_message_map(%MessageSchema{} = msg) do
    meta = msg.metadata || %{}

    suggestions =
      (meta["suggestions"] || [])
      |> Enum.map(fn
        [label, flow] -> {label, flow}
        {label, flow} -> {label, flow}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    %{
      id: msg.id,
      content: msg.content,
      room: msg.room,
      sender_id: msg.sender_id,
      sender: msg.sender || %{email: "olivia@nuvoqs.ai"},
      inserted_at: msg.inserted_at,
      image_url: meta["image_url"],
      suggestions: suggestions,
      bot: is_nil(msg.sender_id)
    }
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), serialize_value(v)} end)
  end

  defp serialize_value(v) when is_tuple(v), do: Tuple.to_list(v) |> Enum.map(&serialize_value/1)
  defp serialize_value(v) when is_list(v), do: Enum.map(v, &serialize_value/1)
  defp serialize_value(v) when is_map(v), do: stringify_keys(v)
  defp serialize_value(v), do: v
end
