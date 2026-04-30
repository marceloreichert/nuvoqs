defmodule Nuvoqs.Miner.Targets.Politic.Br.Senate.PoliticBrSenatePgFollowerTarget do
  @moduledoc """
  The PoliticBrSenatePgFollowerTarget context.
  """

  import Ecto.Query, warn: false
  alias Nuvoqs.Repo

  alias Nuvoqs.Schemas.Politic.Br.Senate.PoliticBrSenateFollowerSchema, as: PoliticBrSenate
  alias Nuvoqs.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any politic_br_senate changes.

  The broadcasted messages match the pattern:

    * {:created, %PoliticBrSenate{}}
    * {:updated, %PoliticBrSenate{}}
    * {:deleted, %PoliticBrSenate{}}

  """
  def subscribe_politic_br_senate_followers(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Nuvoqs.PubSub, "user:#{key}:politic_br_senate_followers")
  end

  defp broadcast_politic_br_senate(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Nuvoqs.PubSub, "user:#{key}:politic_br_senate_followers", message)
  end

  @doc """
  Returns the list of politic_br_senate_followers.

  ## Examples

      iex> list_politic_br_senate_followers(scope)
      [%PoliticBrSenate{}, ...]

  """
  def list_politic_br_senate_followers(%Scope{} = scope) do
    Repo.all(from p in PoliticBrSenate, where: p.user_id == ^scope.user.id)
  end

  @doc """
  Gets a single politic_br_senate.

  Raises `Ecto.NoResultsError` if the Politic br senate does not exist.

  ## Examples

      iex> get_politic_br_senate!(scope, 123)
      %PoliticBrSenate{}

      iex> get_politic_br_senate!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_politic_br_senate!(%Scope{} = scope, id) do
    Repo.get_by!(PoliticBrSenate, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a politic_br_senate.

  ## Examples

      iex> create_politic_br_senate(scope, %{field: value})
      {:ok, %PoliticBrSenate{}}

      iex> create_politic_br_senate(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_politic_br_senate(%Scope{} = scope, attrs) do
    attrs = Map.put(attrs, "user_id", scope.user.id)

    with {:ok, politic_br_senate} <-
           %PoliticBrSenate{}
           |> PoliticBrSenate.changeset(attrs)
           |> Repo.insert() do
      broadcast_politic_br_senate(scope, {:created, politic_br_senate})
      {:ok, politic_br_senate}
    end
  end

  @doc """
  Updates a politic_br_senate.

  ## Examples

      iex> update_politic_br_senate(scope, politic_br_senate, %{field: new_value})
      {:ok, %PoliticBrSenate{}}

      iex> update_politic_br_senate(scope, politic_br_senate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_politic_br_senate(%Scope{} = scope, %PoliticBrSenate{} = politic_br_senate, attrs) do
    true = politic_br_senate.user_id == scope.user.id

    with {:ok, politic_br_senate} <-
           politic_br_senate
           |> PoliticBrSenate.changeset(attrs)
           |> Repo.update() do
      broadcast_politic_br_senate(scope, {:updated, politic_br_senate})
      {:ok, politic_br_senate}
    end
  end

  @doc """
  Deletes a politic_br_senate.

  ## Examples

      iex> delete_politic_br_senate(scope, politic_br_senate)
      {:ok, %PoliticBrSenate{}}

      iex> delete_politic_br_senate(scope, politic_br_senate)
      {:error, %Ecto.Changeset{}}

  """
  def delete_politic_br_senate(%Scope{} = scope, %PoliticBrSenate{} = politic_br_senate) do
    true = politic_br_senate.user_id == scope.user.id

    with {:ok, politic_br_senate = %PoliticBrSenate{}} <-
           Repo.delete(politic_br_senate) do
      broadcast_politic_br_senate(scope, {:deleted, politic_br_senate})
      {:ok, politic_br_senate}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking politic_br_senate changes.

  ## Examples

      iex> change_politic_br_senate(scope, politic_br_senate)
      %Ecto.Changeset{data: %PoliticBrSenate{}}

  """
  def change_politic_br_senate(
        %Scope{} = scope,
        %PoliticBrSenate{} = politic_br_senate,
        attrs \\ %{}
      ) do
    true = politic_br_senate.user_id == scope.user.id

    PoliticBrSenate.changeset(politic_br_senate, attrs)
  end
end
