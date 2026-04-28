defmodule Nuvoqs.PoliticBrSenateFollowersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Nuvoqs.PoliticBrSenateFollowers` context.
  """

  @doc """
  Generate a politic_br_senate.
  """
  def politic_br_senate_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        id: "7488a646-e31f-11e4-aace-600308960662",
        politic_br_senate_member_id: "7488a646-e31f-11e4-aace-600308960662",
        user_id: "7488a646-e31f-11e4-aace-600308960662"
      })

    {:ok, politic_br_senate} = Nuvoqs.PoliticBrSenateFollowers.create_politic_br_senate(scope, attrs)
    politic_br_senate
  end
end
