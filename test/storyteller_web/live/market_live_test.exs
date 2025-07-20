defmodule StorytellerWeb.MarketLiveTest do
  use StorytellerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Storyteller.ProductsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_market(_) do
    market = market_fixture()
    %{market: market}
  end

  describe "Index" do
    setup [:create_market]

    test "lists all markets", %{conn: conn, market: market} do
      {:ok, _index_live, html} = live(conn, ~p"/markets")

      assert html =~ "Listing Markets"
      assert html =~ market.name
    end

    test "saves new market", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/markets")

      assert index_live |> element("a", "New Market") |> render_click() =~
               "New Market"

      assert_patch(index_live, ~p"/markets/new")

      assert index_live
             |> form("#market-form", market: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#market-form", market: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/markets")

      html = render(index_live)
      assert html =~ "Market created successfully"
      assert html =~ "some name"
    end

    test "updates market in listing", %{conn: conn, market: market} do
      {:ok, index_live, _html} = live(conn, ~p"/markets")

      assert index_live |> element("#markets-#{market.id} a", "Edit") |> render_click() =~
               "Edit Market"

      assert_patch(index_live, ~p"/markets/#{market}/edit")

      assert index_live
             |> form("#market-form", market: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#market-form", market: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/markets")

      html = render(index_live)
      assert html =~ "Market updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes market in listing", %{conn: conn, market: market} do
      {:ok, index_live, _html} = live(conn, ~p"/markets")

      assert index_live |> element("#markets-#{market.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#markets-#{market.id}")
    end
  end

  describe "Show" do
    setup [:create_market]

    test "displays market", %{conn: conn, market: market} do
      {:ok, _show_live, html} = live(conn, ~p"/markets/#{market}")

      assert html =~ "Show Market"
      assert html =~ market.name
    end

    test "updates market within modal", %{conn: conn, market: market} do
      {:ok, show_live, _html} = live(conn, ~p"/markets/#{market}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Market"

      assert_patch(show_live, ~p"/markets/#{market}/show/edit")

      assert show_live
             |> form("#market-form", market: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#market-form", market: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/markets/#{market}")

      html = render(show_live)
      assert html =~ "Market updated successfully"
      assert html =~ "some updated name"
    end
  end
end
