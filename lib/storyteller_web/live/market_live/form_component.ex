defmodule StorytellerWeb.MarketLive.FormComponent do
  use StorytellerWeb, :live_component

  alias Storyteller.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage market records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="market-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Market</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{market: market} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Products.change_market(market))
     end)}
  end

  @impl true
  def handle_event("validate", %{"market" => market_params}, socket) do
    changeset = Products.change_market(socket.assigns.market, market_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"market" => market_params}, socket) do
    save_market(socket, socket.assigns.action, market_params)
  end

  defp save_market(socket, :edit, market_params) do
    case Products.update_market(socket.assigns.market, market_params) do
      {:ok, market} ->
        notify_parent({:saved, market})

        {:noreply,
         socket
         |> put_flash(:info, "Market updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_market(socket, :new, market_params) do
    case Products.create_market(market_params) do
      {:ok, market} ->
        notify_parent({:saved, market})

        {:noreply,
         socket
         |> put_flash(:info, "Market created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
