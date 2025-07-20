defmodule StorytellerWeb.JobStoryLive.Index do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories
  alias Storyteller.JobStories.JobStory
  alias Storyteller.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_term, "")
     |> assign(:selected_product_ids, [])
     |> assign(:selected_user_ids, [])
     |> assign(:products, Products.list_products())
     |> assign(:users, Products.list_users())
     |> stream(:job_stories, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_term = params["search"] || ""
    product_ids = parse_list_param(params["product_ids"])
    user_ids = parse_list_param(params["user_ids"])

    filters = %{
      "search" => search_term,
      "product_ids" => product_ids,
      "user_ids" => user_ids
    }

    job_stories = JobStories.list_job_stories(filters)

    {:noreply,
     socket
     |> assign(:search_term, search_term)
     |> assign(:selected_product_ids, product_ids)
     |> assign(:selected_user_ids, user_ids)
     |> stream(:job_stories, job_stories, reset: true)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Job story")
    |> assign(:job_story, JobStories.get_job_story!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Job story")
    |> assign(:job_story, %JobStory{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Job stories")
    |> assign(:job_story, nil)
  end

  @impl true
  def handle_info({StorytellerWeb.JobStoryLive.FormComponent, {:saved, _job_story}}, socket) do
    # Reload the stream with current filters to ensure the new job story
    # is only shown if it matches the current filter criteria
    filters = %{
      "search" => socket.assigns.search_term,
      "product_ids" => socket.assigns.selected_product_ids,
      "user_ids" => socket.assigns.selected_user_ids
    }

    job_stories = JobStories.list_job_stories(filters)
    {:noreply, stream(socket, :job_stories, job_stories, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job_story = JobStories.get_job_story!(id)
    {:ok, _} = JobStories.delete_job_story(job_story)

    {:noreply, stream_delete(socket, :job_stories, job_story)}
  end

  @impl true
  def handle_event("search", %{"search" => search_term}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(search_term, socket.assigns.selected_product_ids, socket.assigns.selected_user_ids)}"
     )}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/job_stories?#{build_filter_params("", socket.assigns.selected_product_ids, socket.assigns.selected_user_ids)}")}
  end

  @impl true
  def handle_event("filter_products", %{"product_ids" => product_ids}, socket) do
    product_ids = parse_list_param(product_ids)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, product_ids, socket.assigns.selected_user_ids)}"
     )}
  end

  @impl true
  def handle_event("filter_users", %{"user_ids" => user_ids}, socket) do
    user_ids = parse_list_param(user_ids)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, socket.assigns.selected_product_ids, user_ids)}"
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/job_stories")}
  end

  @impl true
  def handle_event("filter_change", %{"values" => values, "filter-type" => filter_type}, socket) do
    case filter_type do
      "products" ->
        product_ids = parse_list_param(values)

        {:noreply,
         push_patch(socket,
           to:
             ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, product_ids, socket.assigns.selected_user_ids)}"
         )}

      "users" ->
        user_ids = parse_list_param(values)

        {:noreply,
         push_patch(socket,
           to:
             ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, socket.assigns.selected_product_ids, user_ids)}"
         )}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_products_filter", _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, [], socket.assigns.selected_user_ids)}"
     )}
  end

  @impl true
  def handle_event("clear_users_filter", _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, socket.assigns.selected_product_ids, [])}"
     )}
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => "products", "item_id" => item_id},
        socket
      ) do
    current_ids = socket.assigns.selected_product_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, new_ids, socket.assigns.selected_user_ids)}"
     )}
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => "users", "item_id" => item_id},
        socket
      ) do
    current_ids = socket.assigns.selected_user_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    {:noreply,
     push_patch(socket,
       to:
         ~p"/job_stories?#{build_filter_params(socket.assigns.search_term, socket.assigns.selected_product_ids, new_ids)}"
     )}
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => _filter_type, "item_id" => _item_id},
        socket
      ) do
    {:noreply, socket}
  end

  def build_filter_params(search_term, product_ids, user_ids) do
    params = %{}
    params = if search_term != "", do: Map.put(params, :search, search_term), else: params

    params =
      if product_ids != [],
        do:
          Map.put(
            params,
            :product_ids,
            Enum.join(product_ids, ",")
          ),
        else: params

    params =
      if user_ids != [],
        do: Map.put(params, :user_ids, Enum.join(user_ids, ",")),
        else: params

    params
  end

  defp parse_list_param(nil), do: []
  defp parse_list_param(""), do: []

  defp parse_list_param(param) when is_binary(param) do
    param
    |> String.split(",")
    |> Enum.filter(&(&1 != ""))
  end

  defp parse_list_param(param) when is_list(param), do: param
  defp parse_list_param(_), do: []
end
