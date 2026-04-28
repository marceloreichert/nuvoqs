defmodule Nuvoqs.PoliticBrSenateFollowersTest do
  use Nuvoqs.DataCase

  alias Nuvoqs.PoliticBrSenateFollowers

  describe "politic_br_senate_followers" do
    alias Nuvoqs.PoliticBrSenateFollowers.PoliticBrSenate

    import Nuvoqs.AccountsFixtures, only: [user_scope_fixture: 0]
    import Nuvoqs.PoliticBrSenateFollowersFixtures

    @invalid_attrs %{id: nil, user_id: nil, politic_br_senate_member_id: nil}

    test "list_politic_br_senate_followers/1 returns all scoped politic_br_senate_followers" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      other_politic_br_senate = politic_br_senate_fixture(other_scope)
      assert PoliticBrSenateFollowers.list_politic_br_senate_followers(scope) == [politic_br_senate]
      assert PoliticBrSenateFollowers.list_politic_br_senate_followers(other_scope) == [other_politic_br_senate]
    end

    test "get_politic_br_senate!/2 returns the politic_br_senate with given id" do
      scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      other_scope = user_scope_fixture()
      assert PoliticBrSenateFollowers.get_politic_br_senate!(scope, politic_br_senate.id) == politic_br_senate
      assert_raise Ecto.NoResultsError, fn -> PoliticBrSenateFollowers.get_politic_br_senate!(other_scope, politic_br_senate.id) end
    end

    test "create_politic_br_senate/2 with valid data creates a politic_br_senate" do
      valid_attrs = %{id: "7488a646-e31f-11e4-aace-600308960662", user_id: "7488a646-e31f-11e4-aace-600308960662", politic_br_senate_member_id: "7488a646-e31f-11e4-aace-600308960662"}
      scope = user_scope_fixture()

      assert {:ok, %PoliticBrSenate{} = politic_br_senate} = PoliticBrSenateFollowers.create_politic_br_senate(scope, valid_attrs)
      assert politic_br_senate.id == "7488a646-e31f-11e4-aace-600308960662"
      assert politic_br_senate.user_id == "7488a646-e31f-11e4-aace-600308960662"
      assert politic_br_senate.politic_br_senate_member_id == "7488a646-e31f-11e4-aace-600308960662"
      assert politic_br_senate.user_id == scope.user.id
    end

    test "create_politic_br_senate/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = PoliticBrSenateFollowers.create_politic_br_senate(scope, @invalid_attrs)
    end

    test "update_politic_br_senate/3 with valid data updates the politic_br_senate" do
      scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      update_attrs = %{id: "7488a646-e31f-11e4-aace-600308960668", user_id: "7488a646-e31f-11e4-aace-600308960668", politic_br_senate_member_id: "7488a646-e31f-11e4-aace-600308960668"}

      assert {:ok, %PoliticBrSenate{} = politic_br_senate} = PoliticBrSenateFollowers.update_politic_br_senate(scope, politic_br_senate, update_attrs)
      assert politic_br_senate.id == "7488a646-e31f-11e4-aace-600308960668"
      assert politic_br_senate.user_id == "7488a646-e31f-11e4-aace-600308960668"
      assert politic_br_senate.politic_br_senate_member_id == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_politic_br_senate/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)

      assert_raise MatchError, fn ->
        PoliticBrSenateFollowers.update_politic_br_senate(other_scope, politic_br_senate, %{})
      end
    end

    test "update_politic_br_senate/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = PoliticBrSenateFollowers.update_politic_br_senate(scope, politic_br_senate, @invalid_attrs)
      assert politic_br_senate == PoliticBrSenateFollowers.get_politic_br_senate!(scope, politic_br_senate.id)
    end

    test "delete_politic_br_senate/2 deletes the politic_br_senate" do
      scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      assert {:ok, %PoliticBrSenate{}} = PoliticBrSenateFollowers.delete_politic_br_senate(scope, politic_br_senate)
      assert_raise Ecto.NoResultsError, fn -> PoliticBrSenateFollowers.get_politic_br_senate!(scope, politic_br_senate.id) end
    end

    test "delete_politic_br_senate/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      assert_raise MatchError, fn -> PoliticBrSenateFollowers.delete_politic_br_senate(other_scope, politic_br_senate) end
    end

    test "change_politic_br_senate/2 returns a politic_br_senate changeset" do
      scope = user_scope_fixture()
      politic_br_senate = politic_br_senate_fixture(scope)
      assert %Ecto.Changeset{} = PoliticBrSenateFollowers.change_politic_br_senate(scope, politic_br_senate)
    end
  end
end
