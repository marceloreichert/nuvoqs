defmodule Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "politic_br_senate_followers" do
    belongs_to :user, Nuvoqs.Accounts.User, type: :id

    belongs_to :politic_br_senate_member,
               Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateMemberSchema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:user_id, :politic_br_senate_member_id])
    |> validate_required([:user_id, :politic_br_senate_member_id])
  end
end
