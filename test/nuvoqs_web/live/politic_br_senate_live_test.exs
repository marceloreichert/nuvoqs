defmodule NuvoqsWeb.PoliticBrSenateLiveTest do
  use NuvoqsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Nuvoqs.PoliticBrSenateFollowersFixtures

  @create_attrs %{id: "7488a646-e31f-11e4-aace-600308960662", user_id: "7488a646-e31f-11e4-aace-600308960662", politic_br_senate_member_id: "7488a646-e31f-11e4-aace-600308960662"}
  @update_attrs %{id: "7488a646-e31f-11e4-aace-600308960668", user_id: "7488a646-e31f-11e4-aace-600308960668", politic_br_senate_member_id: "7488a646-e31f-11e4-aace-600308960668"}
  @invalid_attrs %{id: nil, user_id: nil, politic_br_senate_member_id: nil}

  setup :register_and_log_in_user

  defp create_politic_br_senate(%{scope: scope}) do
    politic_br_senate = politic_br_senate_fixture(scope)

    %{politic_br_senate: politic_br_senate}
  end

  describe "Index" do
    setup [:create_politic_br_senate]

    test "lists all politic_br_senate_followers", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/politic_br_senate_followers")

      assert html =~ "Listing Politic br senate followers"
    end

    test "saves new politic_br_senate", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/politic_br_senate_followers")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Politic br senate")
               |> render_click()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers/new")

      assert render(form_live) =~ "New Politic br senate"

      assert form_live
             |> form("#politic_br_senate-form", politic_br_senate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#politic_br_senate-form", politic_br_senate: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers")

      html = render(index_live)
      assert html =~ "Politic br senate created successfully"
    end

    test "updates politic_br_senate in listing", %{conn: conn, politic_br_senate: politic_br_senate} do
      {:ok, index_live, _html} = live(conn, ~p"/politic_br_senate_followers")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#politic_br_senate_followers-#{politic_br_senate.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers/#{politic_br_senate}/edit")

      assert render(form_live) =~ "Edit Politic br senate"

      assert form_live
             |> form("#politic_br_senate-form", politic_br_senate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#politic_br_senate-form", politic_br_senate: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers")

      html = render(index_live)
      assert html =~ "Politic br senate updated successfully"
    end

    test "deletes politic_br_senate in listing", %{conn: conn, politic_br_senate: politic_br_senate} do
      {:ok, index_live, _html} = live(conn, ~p"/politic_br_senate_followers")

      assert index_live |> element("#politic_br_senate_followers-#{politic_br_senate.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#politic_br_senate_followers-#{politic_br_senate.id}")
    end
  end

  describe "Show" do
    setup [:create_politic_br_senate]

    test "displays politic_br_senate", %{conn: conn, politic_br_senate: politic_br_senate} do
      {:ok, _show_live, html} = live(conn, ~p"/politic_br_senate_followers/#{politic_br_senate}")

      assert html =~ "Show Politic br senate"
    end

    test "updates politic_br_senate and returns to show", %{conn: conn, politic_br_senate: politic_br_senate} do
      {:ok, show_live, _html} = live(conn, ~p"/politic_br_senate_followers/#{politic_br_senate}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers/#{politic_br_senate}/edit?return_to=show")

      assert render(form_live) =~ "Edit Politic br senate"

      assert form_live
             |> form("#politic_br_senate-form", politic_br_senate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#politic_br_senate-form", politic_br_senate: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/politic_br_senate_followers/#{politic_br_senate}")

      html = render(show_live)
      assert html =~ "Politic br senate updated successfully"
    end
  end
end
