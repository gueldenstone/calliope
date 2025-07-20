defmodule StorytellerWeb.UserLive.FormComponent do
  use StorytellerWeb, :live_component

  alias Storyteller.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:pseudonym]} type="text" label="Pseudonym" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          prompt="Choose a value"
          options={Ecto.Enum.values(Storyteller.Products.User, :type)}
        />

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">Associated Markets</label>
          <div class="space-y-2">
            <%= for market <- @markets do %>
              <label class="flex items-center">
                <input
                  type="checkbox"
                  name="user[market_ids][]"
                  value={market.id}
                  checked={market.id in @selected_market_ids}
                  class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span class="ml-2 text-sm text-gray-900">
                  {market.name}
                </span>
              </label>
            <% end %>
          </div>
          <%= if Enum.empty?(@markets) do %>
            <p class="text-sm text-gray-500">No markets available. Create some markets first.</p>
          <% end %>
        </div>

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">Associated Job Stories</label>
          <div class="space-y-2">
            <%= for job_story <- @job_stories do %>
              <label class="flex items-center">
                <input
                  type="checkbox"
                  name="user[job_story_ids][]"
                  value={job_story.id}
                  checked={job_story.id in @selected_job_story_ids}
                  class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span class="ml-2 text-sm text-gray-900">
                  {job_story.title}
                </span>
              </label>
            <% end %>
          </div>
          <%= if Enum.empty?(@job_stories) do %>
            <p class="text-sm text-gray-500">
              No job stories available. Create some job stories first.
            </p>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    # Load all markets and job stories for selection
    markets = Products.list_markets()
    job_stories = Storyteller.JobStories.list_job_stories()

    # Get currently selected market IDs
    selected_market_ids =
      case user.markets do
        %Ecto.Association.NotLoaded{} -> []
        markets when is_list(markets) -> Enum.map(markets, & &1.id)
        _ -> []
      end

    # Get currently selected job story IDs
    selected_job_story_ids =
      case user.job_stories do
        %Ecto.Association.NotLoaded{} -> []
        job_stories when is_list(job_stories) -> Enum.map(job_stories, & &1.id)
        _ -> []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:markets, markets)
     |> assign(:job_stories, job_stories)
     |> assign(:selected_market_ids, selected_market_ids)
     |> assign(:selected_job_story_ids, selected_job_story_ids)
     |> assign_new(:form, fn ->
       to_form(Products.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    # Extract selected market IDs from the form params
    selected_market_ids =
      case user_params do
        %{"market_ids" => market_ids} when is_list(market_ids) -> market_ids
        _ -> []
      end

    # Extract selected job story IDs from the form params
    selected_job_story_ids =
      case user_params do
        %{"job_story_ids" => job_story_ids} when is_list(job_story_ids) -> job_story_ids
        _ -> []
      end

    changeset = Products.change_user(socket.assigns.user, user_params)

    {:noreply,
     socket
     |> assign(:selected_market_ids, selected_market_ids)
     |> assign(:selected_job_story_ids, selected_job_story_ids)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    # Ensure market_ids and job_story_ids are always present (empty array if none selected)
    user_params =
      user_params
      |> Map.put_new("market_ids", [])
      |> Map.put_new("job_story_ids", [])

    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Products.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Products.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
