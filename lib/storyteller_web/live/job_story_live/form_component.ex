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

        <:actions>
          <.button phx-disable-with="Saving...">Save Job story</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{job_story: job_story} = assigns, socket) do
    # Load all products for selection
    products = Products.list_products()

    # Get currently selected product IDs
    selected_product_ids =
      case job_story.products do
        %Ecto.Association.NotLoaded{} -> []
        products when is_list(products) -> Enum.map(products, & &1.id)
        _ -> []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:products, products)
     |> assign(:selected_product_ids, selected_product_ids)
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

    changeset = JobStories.change_job_story(socket.assigns.job_story, job_story_params)

    {:noreply,
     socket
     |> assign(:selected_product_ids, selected_product_ids)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"job_story" => job_story_params}, socket) do
    # Ensure product_ids is always present (empty array if no products selected)
    job_story_params =
      if Map.has_key?(job_story_params, "product_ids") do
        job_story_params
      else
        Map.put(job_story_params, "product_ids", [])
      end

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
