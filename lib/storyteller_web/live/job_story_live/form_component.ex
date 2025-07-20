defmodule StorytellerWeb.JobStoryLive.FormComponent do
  use StorytellerWeb, :live_component

  alias Storyteller.JobStories
  alias Storyteller.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage job_story records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="job_story-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:situation]} type="text" label="Situation" />
        <.input field={@form[:motivation]} type="text" label="Motivation" />
        <.input field={@form[:outcome]} type="text" label="Outcome" />

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">Associated Products</label>
          <div class="space-y-2">
            <%= for product <- @products do %>
              <label class="flex items-center">
                <input
                  type="checkbox"
                  name="job_story[product_ids][]"
                  value={product.id}
                  checked={product.id in @selected_product_ids}
                  class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span class="ml-2 text-sm text-gray-900">
                  {product.name} - {product.description}
                </span>
              </label>
            <% end %>
          </div>
          <%= if Enum.empty?(@products) do %>
            <p class="text-sm text-gray-500">No products available. Create some products first.</p>
          <% end %>
        </div>

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">Associated Users</label>
          <div class="space-y-2">
            <%= for user <- @users do %>
              <label class="flex items-center">
                <input
                  type="checkbox"
                  name="job_story[user_ids][]"
                  value={user.id}
                  checked={user.id in @selected_user_ids}
                  class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span class="ml-2 text-sm text-gray-900">
                  {user.pseudonym} - {user.type}
                </span>
              </label>
            <% end %>
          </div>
          <%= if Enum.empty?(@users) do %>
            <p class="text-sm text-gray-500">No users available. Create some users first.</p>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Job story</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{job_story: job_story} = assigns, socket) do
    # Load all products and users for selection
    products = Products.list_products()
    users = Products.list_users()

    # Get currently selected product IDs
    selected_product_ids =
      case job_story.products do
        %Ecto.Association.NotLoaded{} -> []
        products when is_list(products) -> Enum.map(products, & &1.id)
        _ -> []
      end

    # Get currently selected user IDs
    selected_user_ids =
      case job_story.users do
        %Ecto.Association.NotLoaded{} -> []
        users when is_list(users) -> Enum.map(users, & &1.id)
        _ -> []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:products, products)
     |> assign(:users, users)
     |> assign(:selected_product_ids, selected_product_ids)
     |> assign(:selected_user_ids, selected_user_ids)
     |> assign_new(:form, fn ->
       to_form(JobStories.change_job_story(job_story))
     end)}
  end

  @impl true
  def handle_event("validate", %{"job_story" => job_story_params}, socket) do
    # Extract selected product IDs from the form params
    selected_product_ids =
      case job_story_params do
        %{"product_ids" => product_ids} when is_list(product_ids) -> product_ids
        _ -> []
      end

    # Extract selected user IDs from the form params
    selected_user_ids =
      case job_story_params do
        %{"user_ids" => user_ids} when is_list(user_ids) -> user_ids
        _ -> []
      end

    changeset = JobStories.change_job_story(socket.assigns.job_story, job_story_params)

    {:noreply,
     socket
     |> assign(:selected_product_ids, selected_product_ids)
     |> assign(:selected_user_ids, selected_user_ids)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"job_story" => job_story_params}, socket) do
    # Ensure product_ids and user_ids are always present (empty array if none selected)
    job_story_params =
      job_story_params
      |> Map.put_new("product_ids", [])
      |> Map.put_new("user_ids", [])

    save_job_story(socket, socket.assigns.action, job_story_params)
  end

  defp save_job_story(socket, :edit, job_story_params) do
    case JobStories.update_job_story(socket.assigns.job_story, job_story_params) do
      {:ok, job_story} ->
        notify_parent({:saved, job_story})

        {:noreply,
         socket
         |> put_flash(:info, "Job story updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_job_story(socket, :new, job_story_params) do
    case JobStories.create_job_story(job_story_params) do
      {:ok, job_story} ->
        notify_parent({:saved, job_story})

        {:noreply,
         socket
         |> put_flash(:info, "Job story created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
