defmodule Nuvoqs.Repo.Migrations.AddMetadataAndNullableSenderToChatMessages do
  use Ecto.Migration

  def change do
    alter table(:chat_messages) do
      modify :sender_id, references(:users, type: :id), null: true,
             from: {references(:users, type: :id), null: false}
      add :metadata, :map, default: %{}
    end
  end
end
