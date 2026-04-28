defmodule Nuvoqs.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :content, :text, null: false
      add :room, :string, null: false, default: "general"
      add :sender_id, references(:users, type: :id), null: false

      timestamps(updated_at: false)
    end

    create index(:chat_messages, [:room, :inserted_at])
  end
end
