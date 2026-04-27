defmodule Nuvoqs.Repo.Migrations.CreateTypeVoices do
  use Ecto.Migration

  def change do
    create table(:type_voices, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:type_voices, [:name])
  end
end
