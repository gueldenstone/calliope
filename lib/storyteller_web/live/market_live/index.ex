defmodule StorytellerWeb.MarketLive.Index do
  use StorytellerWeb, :live_view

  alias Storyteller.Products
  alias Storyteller.Products.Market

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :markets, Products.list_markets())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Market")
    |> assign(:market, Products.get_market!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Market")
    |> assign(:market, %Market{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Markets")
    |> assign(:market, nil)
  end

  @impl true
  def handle_info({StorytellerWeb.MarketLive.FormComponent, {:saved, market}}, socket) do
    {:noreply, stream_insert(socket, :markets, market)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    market = Products.get_market!(id)
    {:ok, _} = Products.delete_market(market)

    {:noreply, stream_delete(socket, :markets, market)}
  end
end
