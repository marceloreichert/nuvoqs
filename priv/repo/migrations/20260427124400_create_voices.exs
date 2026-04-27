defmodule Nuvoqs.Repo.Migrations.CreateVoices do
  use Ecto.Migration

  def change do
    create table(:voices, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :tag, :string
      add :sync_time, :integer
      add :type_voice_id, :uuid

      timestamps()
    end

    create unique_index(:voices, [:tag])
  end
end
