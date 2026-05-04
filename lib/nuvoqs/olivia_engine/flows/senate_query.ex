defmodule Nuvoqs.OliviaEngine.Flows.SenateQuery do
  @moduledoc """
  Query helpers for senate flows — wraps Repo access so flow actions
  stay free of database concerns.
  """

  import Ecto.Query
  alias Nuvoqs.Repo
  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateMemberSchema
  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema

  @doc "Search senators by name fragment (case-insensitive)."
  def search_by_name(name) do
    pattern = "%#{String.downcase(name)}%"

    query =
      from m in PoliticBrSenateMemberSchema,
        where: fragment("lower(?->>'name') LIKE ?", m.data, ^pattern),
        limit: 5

    Repo.all(query)
  end

  @doc "List senators — first 15 alphabetically."
  def list_all do
    query =
      from m in PoliticBrSenateMemberSchema,
        order_by: fragment("?->>'name'", m.data),
        limit: 15

    Repo.all(query)
  end

  @doc "Unfollow a senator."
  def unfollow(user_id, member_id) do
    query =
      from f in PoliticBrSenateFollowerSchema,
        where: f.user_id == ^user_id and f.politic_br_senate_member_id == ^member_id

    case Repo.delete_all(query) do
      {0, _} -> {:error, :not_following}
      {_, _} -> :ok
    end
  end

  @doc "Check if user is following a specific member."
  def following?(user_id, member_id) do
    query =
      from f in PoliticBrSenateFollowerSchema,
        where: f.user_id == ^user_id and f.politic_br_senate_member_id == ^member_id

    Repo.exists?(query)
  end

  @doc "Count senators the user is following."
  def count_followed(user_id) do
    query =
      from f in PoliticBrSenateFollowerSchema,
        where: f.user_id == ^user_id,
        select: count(f.id)

    Repo.one(query)
  end

  @doc "Follow a senator: create follower record for user."
  def follow(user_id, member_id) do
    %PoliticBrSenateFollowerSchema{}
    |> PoliticBrSenateFollowerSchema.changeset(%{
      user_id: user_id,
      politic_br_senate_member_id: member_id
    })
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc "List senators the user is following."
  def list_followed(user_id) do
    query =
      from f in PoliticBrSenateFollowerSchema,
        where: f.user_id == ^user_id,
        join: m in assoc(f, :politic_br_senate_member),
        select: m

    Repo.all(query)
  end

  @doc "List senators the user is following with formatted output and photo URL."
  def list_followed_with_photos(user_id) do
    list_followed(user_id)
    |> Enum.map(fn member ->
      %{label: format_member(member), url_photo: member.data["url_photo"]}
    end)
  end

  @doc "Format a member record for display in chat."
  def format_member(%PoliticBrSenateMemberSchema{data: data}) when is_map(data) do
    name = data["name"] || "Desconhecido"
    party = data["party_acronym"] || "—"
    state = data["uf"] || "—"
    "#{name} (#{party}/#{state})"
  end

  def format_member(_), do: "Senador não encontrado"

  @doc "Format a member with all available fields."
  def format_member_full(%PoliticBrSenateMemberSchema{data: data}) when is_map(data) do
    lines = [
      "Nome: #{data["full_name"] || data["name"] || "—"}",
      "Nome parlamentar: #{data["name"] || "—"}",
      "Partido: #{data["party_acronym"] || "—"}/#{data["uf"] || "—"}"
    ]

    lines = if email = data["email"], do: lines ++ ["E-mail: #{email}"], else: lines
    lines = if url = data["url_homepage"], do: lines ++ ["Página: #{url}"], else: lines

    Enum.join(lines, "\n")
  end

  def format_member_full(_), do: "Dados não disponíveis"
end
