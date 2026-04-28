defmodule Nuvoqs.Schemas.TypeVoiceSchema do
  use Nuvoqs.Schema
  import Ecto.Changeset

  schema "type_voices" do
    field :name, :string

    timestamps()
  end

  @fields [
    :name
  ]
  @fields_required [:name]

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, @fields)
    |> validate_required(@fields_required)
  end
end
