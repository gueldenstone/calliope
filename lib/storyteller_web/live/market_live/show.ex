defmodule StorytellerWeb.MarketLive.Show do
  use StorytellerWeb, :live_view

  alias Storyteller.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:market, Products.get_market!(id))}
  end

  defp page_title(:show), do: "Show Market"
  defp page_title(:edit), do: "Edit Market"
end
