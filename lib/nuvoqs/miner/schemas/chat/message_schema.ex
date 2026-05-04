defmodule Nuvoqs.Schemas.Chat.MessageSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :content, :string
    field :room, :string, default: "general"
    field :metadata, :map, default: %{}

    belongs_to :sender, Nuvoqs.Accounts.User, type: :id

    timestamps(updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :room, :sender_id])
    |> validate_required([:content, :sender_id])
    |> validate_length(:content, min: 1, max: 2000)
  end

  def bot_changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :room, :metadata])
    |> validate_length(:content, max: 2000)
    |> then(fn cs ->
      if Ecto.Changeset.get_field(cs, :content) == nil,
        do: Ecto.Changeset.put_change(cs, :content, ""),
        else: cs
    end)
  end
end
