defmodule Nuvoqs.Voices.Targets.Politic.Br.Senate.PoliticBrSenatePGTarget do
  @moduledoc false

  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateMemberSchema
  alias Nuvoqs.Repo

  def post_member(attrs) do
    case %PoliticBrSenateMemberSchema{}
           |> PoliticBrSenateMemberSchema.changeset(attrs)
           |> Repo.insert() do
      {:ok, member} -> {:ok, member.id}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_member_by(params) do
    case Repo.get_by(PoliticBrSenateMemberSchema, params) do
      nil -> {:ok, :not_found}
      member -> {:ok, member}
    end
  end
end
