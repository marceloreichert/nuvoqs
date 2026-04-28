defmodule Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateMemberSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "politic_br_senate_members" do
    field :identifier, :string
    field :data, :map

    belongs_to :voice, Nuvoqs.Schemas.VoiceSchema

    timestamps()
  end

  @fields [
    :identifier,
    :data,
    :voice_id
  ]
  @fields_required [:identifier]

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, @fields)
    |> validate_required(@fields_required)
  end
end
