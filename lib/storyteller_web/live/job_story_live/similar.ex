defmodule StorytellerWeb.JobStoryLive.Similar do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories
  alias Storyteller.Embeddings
  alias Storyteller.Products

  @impl true
  def mount(_params, _session, socket) do
    # Check if embeddings service is ready
    embeddings_ready = Embeddings.ready?()

    {:ok,
     socket
     |> assign(:embeddings_ready, embeddings_ready)
     |> assign(:selected_job_story, nil)
     |> assign(:similar_stories, [])
     |> assign(:loading_similar, false)
     |> assign(:similarity_weights, %{situation: 0.4, motivation: 0.3, outcome: 0.3})
     |> assign(:min_scores, %{situation: 0, motivation: 0, outcome: 0})
     |> assign(:sort_by, :overall)
     |> assign(:show_advanced_controls, false)
     |> assign(:selected_product_ids, [])
     |> assign(:selected_user_ids, [])
     |> assign(:products, Products.list_products())
     |> assign(:users, Products.list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Parse URL parameters
    selected_job_story_id = params["job_story_id"]
    product_ids = parse_list_param(params["product_ids"])
    user_ids = parse_list_param(params["user_ids"])
    weights = parse_weights_params(params["weights"])
    min_scores = parse_min_scores_params(params["min_scores"])
    sort_by = parse_sort_by_param(params["sort_by"])

    # Load all job stories for the left panel
    job_stories = JobStories.list_job_stories()

    # Find the selected job story if ID is provided
    selected_job_story =
      if selected_job_story_id do
        Enum.find(job_stories, fn js -> js.id == selected_job_story_id end)
      end

    # Calculate similar stories if a job story is selected
    similar_stories =
      if selected_job_story do
        other_stories = Enum.reject(job_stories, fn js -> js.id == selected_job_story.id end)

        similar_stories =
          find_similar_stories_enhanced(selected_job_story, other_stories, %{
            similarity_weights: weights,
            min_scores: min_scores,
            sort_by: sort_by,
            selected_product_ids: product_ids,
            selected_user_ids: user_ids
          })

        apply_filters_to_similar_stories(similar_stories, %{
          selected_product_ids: product_ids,
          selected_user_ids: user_ids
        })
      else
        []
      end

    {:noreply,
     socket
     |> assign(:page_title, "Explore Similar Job Stories")
     |> assign(:job_stories, job_stories)
     |> assign(:selected_job_story, selected_job_story)
     |> assign(:similar_stories, similar_stories)
     |> assign(:selected_product_ids, product_ids)
     |> assign(:selected_user_ids, user_ids)
     |> assign(:similarity_weights, weights)
     |> assign(:min_scores, min_scores)
     |> assign(:sort_by, sort_by)
     |> assign(:show_advanced_controls, false)
     |> assign(:loading_similar, false)}
  end

  @impl true
  def handle_event("select_job_story", %{"id" => job_story_id}, socket) do
    # Set loading state first
    socket = assign(socket, :loading_similar, true)

    # Build URL with the selected job story and current filters
    url_params = build_url_params(job_story_id, socket.assigns)

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event("toggle_advanced_controls", _params, socket) do
    new_advanced_state = !socket.assigns.show_advanced_controls

    {:noreply, assign(socket, :show_advanced_controls, new_advanced_state)}
  end

  @impl true
  def handle_event("update_weights", %{"weights" => weights}, socket) do
    # Convert string values to floats
    weights = %{
      situation: parse_float(weights["situation"], 0.4),
      motivation: parse_float(weights["motivation"], 0.3),
      outcome: parse_float(weights["outcome"], 0.3)
    }

    # Normalize weights to sum to 1.0
    total = weights.situation + weights.motivation + weights.outcome

    normalized_weights = %{
      situation: weights.situation / total,
      motivation: weights.motivation / total,
      outcome: weights.outcome / total
    }

    socket = assign(socket, :similarity_weights, normalized_weights)

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event("update_min_scores", %{"min_scores" => min_scores}, socket) do
    # Convert string values to integers (percentages)
    min_scores = %{
      situation: parse_percentage(min_scores["situation"], 0),
      motivation: parse_percentage(min_scores["motivation"], 0),
      outcome: parse_percentage(min_scores["outcome"], 0)
    }

    socket = assign(socket, :min_scores, min_scores)

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event("update_sort_by", %{"sort_by" => sort_by}, socket) do
    sort_by = String.to_existing_atom(sort_by)
    socket = assign(socket, :sort_by, sort_by)

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  # Filter event handlers
  @impl true
  def handle_event("toggle_filter", %{"filter_type" => "products", "item_id" => item_id}, socket) do
    current_ids = socket.assigns.selected_product_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    socket = assign(socket, :selected_product_ids, new_ids)

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event("toggle_filter", %{"filter_type" => "users", "item_id" => item_id}, socket) do
    current_ids = socket.assigns.selected_user_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    socket = assign(socket, :selected_user_ids, new_ids)

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => _filter_type, "item_id" => _item_id},
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_products_filter", _params, socket) do
    socket = assign(socket, :selected_product_ids, [])

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  @impl true
  def handle_event("clear_users_filter", _params, socket) do
    socket = assign(socket, :selected_user_ids, [])

    url_params =
      build_url_params(
        socket.assigns.selected_job_story && socket.assigns.selected_job_story.id,
        socket.assigns
      )

    {:noreply, push_patch(socket, to: ~p"/job_stories/similar?#{url_params}")}
  end

  defp find_similar_stories_enhanced(selected_story, other_stories, assigns) do
    opts = [
      limit: 100,
      weights: assigns.similarity_weights,
      min_scores: assigns.min_scores,
      sort_by: assigns.sort_by
    ]

    # Use the enhanced service function to find similar stories
    # No need for serving parameter since we use stored embeddings
    Embeddings.find_similar_to_job_story_enhanced_service(selected_story, other_stories, opts)
  end

  defp parse_float(value, default) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> default
    end
  end

  defp parse_float(value, _default) when is_number(value), do: value
  defp parse_float(_, default), do: default

  defp parse_percentage(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_percentage(value, _default) when is_number(value), do: value
  defp parse_percentage(_, default), do: default

  defp format_similarity_score(similarity) do
    percentage = (similarity * 100) |> Float.round(1)
    "#{percentage}%"
  end

  defp get_component_color(score) when score >= 0.8, do: "bg-green-100 text-green-800"
  defp get_component_color(score) when score >= 0.6, do: "bg-yellow-100 text-yellow-800"
  defp get_component_color(_score), do: "bg-red-100 text-red-800"

  # Applies product and user filters to similar stories results.
  defp apply_filters_to_similar_stories(similar_stories, assigns) do
    similar_stories
    |> Enum.filter(fn {job_story, _similarity_details} ->
      # Check if job story has any of the selected products
      product_filter_passed =
        if assigns.selected_product_ids == [] do
          true
        else
          job_story_product_ids = Enum.map(job_story.products, & &1.id)
          Enum.any?(assigns.selected_product_ids, &(&1 in job_story_product_ids))
        end

      # Check if job story has any of the selected users
      user_filter_passed =
        if assigns.selected_user_ids == [] do
          true
        else
          job_story_user_ids = Enum.map(job_story.users, & &1.id)
          Enum.any?(assigns.selected_user_ids, &(&1 in job_story_user_ids))
        end

      product_filter_passed and user_filter_passed
    end)
  end

  # URL parameter parsing functions
  defp parse_list_param(nil), do: []
  defp parse_list_param(""), do: []

  defp parse_list_param(param) when is_binary(param) do
    param
    |> String.split(",")
    |> Enum.filter(&(&1 != ""))
  end

  defp parse_list_param(param) when is_list(param), do: param
  defp parse_list_param(_), do: []

  defp parse_weights_params(nil), do: %{situation: 0.4, motivation: 0.3, outcome: 0.3}

  defp parse_weights_params(weights_str) when is_binary(weights_str) do
    weights_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_float(&1, 0.0))
    |> case do
      [situation, motivation, outcome] ->
        total = situation + motivation + outcome

        if total > 0 do
          %{
            situation: situation / total,
            motivation: motivation / total,
            outcome: outcome / total
          }
        else
          %{situation: 0.4, motivation: 0.3, outcome: 0.3}
        end

      _ ->
        %{situation: 0.4, motivation: 0.3, outcome: 0.3}
    end
  end

  defp parse_weights_params(_), do: %{situation: 0.4, motivation: 0.3, outcome: 0.3}

  defp parse_min_scores_params(nil), do: %{situation: 0, motivation: 0, outcome: 0}

  defp parse_min_scores_params(scores_str) when is_binary(scores_str) do
    scores_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_percentage(&1, 0))
    |> case do
      [situation, motivation, outcome] ->
        %{situation: situation, motivation: motivation, outcome: outcome}

      _ ->
        %{situation: 0, motivation: 0, outcome: 0}
    end
  end

  defp parse_min_scores_params(_), do: %{situation: 0, motivation: 0, outcome: 0}

  defp parse_sort_by_param(nil), do: :overall

  defp parse_sort_by_param(sort_by) when is_binary(sort_by) do
    case sort_by do
      "situation" -> :situation
      "motivation" -> :motivation
      "outcome" -> :outcome
      _ -> :overall
    end
  end

  defp parse_sort_by_param(_), do: :overall

  # URL building functions
  defp build_url_params(job_story_id, assigns) do
    params = %{}

    # Add job story ID
    params = if job_story_id, do: Map.put(params, :job_story_id, job_story_id), else: params

    # Add product IDs
    params =
      if assigns.selected_product_ids != [] do
        Map.put(params, :product_ids, Enum.join(assigns.selected_product_ids, ","))
      else
        params
      end

    # Add user IDs
    params =
      if assigns.selected_user_ids != [] do
        Map.put(params, :user_ids, Enum.join(assigns.selected_user_ids, ","))
      else
        params
      end

    # Add weights
    weights_str =
      "#{assigns.similarity_weights.situation},#{assigns.similarity_weights.motivation},#{assigns.similarity_weights.outcome}"

    params = Map.put(params, :weights, weights_str)

    # Add min scores
    scores_str =
      "#{assigns.min_scores.situation},#{assigns.min_scores.motivation},#{assigns.min_scores.outcome}"

    params = Map.put(params, :min_scores, scores_str)

    # Add sort by
    params = Map.put(params, :sort_by, to_string(assigns.sort_by))

    params
  end
end
