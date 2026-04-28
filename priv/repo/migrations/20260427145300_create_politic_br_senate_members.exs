defmodule Nuvoqs.Repo.Migrations.CreatePoliticBrSenateMembers do
  use Ecto.Migration

  def change do
    create table(:politic_br_senate_members, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :identifier, :string
      add :data, :map

      add :voice_id, references(:voices, type: :binary_id)

      timestamps()
    end

    create unique_index(:politic_br_senate_members, [:identifier])
  end
end
