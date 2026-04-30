defmodule Nuvoqs.Miner.Schemas.VoiceSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "voices" do
    field :name, :string
    field :tag, :string
    field :sync_time, :integer

    belongs_to :type_voice, Nuvoqs.Schemas.TypeVoiceSchema

    timestamps()
  end

  @fields [
    :name,
    :tag,
    :sync_time,
    :type_voice_id
  ]
  @fields_required [:name, :tag, :sync_time, :type_voice_id]

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, @fields)
    |> validate_required(@fields_required)
  end
end
