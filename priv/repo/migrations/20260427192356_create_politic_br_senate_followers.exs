defmodule Nuvoqs.Repo.Migrations.CreatePoliticBrSenateFollowers do
  use Ecto.Migration

  def change do
    create table(:politic_br_senate_followers, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :politic_br_senate_member_id,
          references(:politic_br_senate_members, type: :uuid, on_delete: :delete_all)

      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:politic_br_senate_followers, [:user_id])
  end
end
