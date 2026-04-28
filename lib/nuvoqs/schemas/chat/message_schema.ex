defmodule Nuvoqs.Schemas.Chat.MessageSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :content, :string
    field :room, :string, default: "general"

    belongs_to :sender, Nuvoqs.Accounts.User, type: :id

    timestamps(updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :room, :sender_id])
    |> validate_required([:content, :sender_id])
    |> validate_length(:content, min: 1, max: 2000)
  end
end
