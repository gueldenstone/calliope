defmodule StorytellerWeb.JobStoryLive.Index do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories
  alias Storyteller.JobStories.JobStory
  alias Storyteller.Products
  alias Storyteller.Embeddings

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:filters, %{
       search_term: "",
       selected_product_ids: [],
       selected_user_ids: []
     })
     |> assign(:similarity_search, %{
       reference_job_story_id: nil,
       weights: %{situation: 0.4, motivation: 0.3, outcome: 0.3},
       min_scores: %{situation: 0, motivation: 0, outcome: 0},
       sort_by: :overall,
       show_advanced_controls: false
     })
     |> assign(:products, Products.list_products())
     |> assign(:users, Products.list_users())
     |> assign(:embeddings_ready, Embeddings.ready?())
     |> assign(:job_stories_with_similarity, [])
     |> stream(:job_stories, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Parse filter parameters
    filters = %{
      search_term: params["search"] || "",
      selected_product_ids: parse_list_param(params["product_ids"]),
      selected_user_ids: parse_list_param(params["user_ids"])
    }

    # Parse similarity search parameters
    similarity_search = %{
      reference_job_story_id: params["reference_job_story_id"],
      weights: parse_weights_params(params["weights"]),
      min_scores: parse_min_scores_params(params["min_scores"]),
      sort_by: parse_sort_by_param(params["sort_by"]),
      show_advanced_controls:
        get_in(socket.assigns, [:similarity_search, :show_advanced_controls]) || false
    }

    # Build filters for JobStories context
    job_story_filters = %{
      search: filters.search_term,
      product_ids: filters.selected_product_ids,
      user_ids: filters.selected_user_ids,
      reference_job_story_id: similarity_search.reference_job_story_id,
      similarity_weights: similarity_search.weights,
      min_scores: similarity_search.min_scores,
      sort_by: similarity_search.sort_by
    }

    job_stories = JobStories.list_job_stories(job_story_filters)

    # Calculate similarity details for each job story if a reference story is selected
    job_stories_with_similarity =
      if similarity_search.reference_job_story_id do
        reference_job_story =
          Enum.find(job_stories, fn js -> js.id == similarity_search.reference_job_story_id end)

        if reference_job_story do
          Enum.map(job_stories, fn job_story ->
            similarity_details =
              calculate_similarity_details(
                job_story,
                reference_job_story,
                similarity_search.weights
              )

            {job_story, similarity_details}
          end)
        else
          Enum.map(job_stories, fn job_story -> {job_story, nil} end)
        end
      else
        Enum.map(job_stories, fn job_story -> {job_story, nil} end)
      end

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:similarity_search, similarity_search)
     |> assign(:job_stories_with_similarity, job_stories_with_similarity)
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
      search: socket.assigns.filters.search_term,
      product_ids: socket.assigns.filters.selected_product_ids,
      user_ids: socket.assigns.filters.selected_user_ids,
      reference_job_story_id: socket.assigns.similarity_search.reference_job_story_id,
      similarity_weights: socket.assigns.similarity_search.weights,
      min_scores: socket.assigns.similarity_search.min_scores,
      sort_by: socket.assigns.similarity_search.sort_by
    }

    job_stories = JobStories.list_job_stories(filters)

    # Calculate similarity details for each job story if a reference story is selected
    job_stories_with_similarity =
      if socket.assigns.similarity_search.reference_job_story_id do
        reference_job_story =
          Enum.find(job_stories, fn js ->
            js.id == socket.assigns.similarity_search.reference_job_story_id
          end)

        if reference_job_story do
          Enum.map(job_stories, fn job_story ->
            similarity_details =
              calculate_similarity_details(
                job_story,
                reference_job_story,
                socket.assigns.similarity_search.weights
              )

            {job_story, similarity_details}
          end)
        else
          Enum.map(job_stories, fn job_story -> {job_story, nil} end)
        end
      else
        Enum.map(job_stories, fn job_story -> {job_story, nil} end)
      end

    {:noreply,
     socket
     |> assign(:job_stories_with_similarity, job_stories_with_similarity)
     |> stream(:job_stories, job_stories, reset: true)}
  end

  # Helper function to build filter parameters and push patch
  defp push_path_and_apply_filters(socket) do
    params = build_filter_params(socket.assigns.filters, socket.assigns.similarity_search)

    {:noreply, push_patch(socket, to: ~p"/job_stories?#{params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job_story = JobStories.get_job_story!(id)
    {:ok, _} = JobStories.delete_job_story(job_story)

    {:noreply, stream_delete(socket, :job_stories, job_story)}
  end

  @impl true
  def handle_event("search", %{"search" => search_term}, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:filters, Map.put(socket.assigns.filters, :search_term, search_term))
    )
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:filters, Map.put(socket.assigns.filters, :search_term, ""))
    )
  end

  @impl true
  def handle_event("filter_products", %{"product_ids" => product_ids}, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(
        :filters,
        Map.put(socket.assigns.filters, :selected_product_ids, parse_list_param(product_ids))
      )
    )
  end

  @impl true
  def handle_event("filter_users", %{"user_ids" => user_ids}, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(
        :filters,
        Map.put(socket.assigns.filters, :selected_user_ids, parse_list_param(user_ids))
      )
    )
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:filters, %{search_term: "", selected_product_ids: [], selected_user_ids: []})
    )
  end

  @impl true
  def handle_event("filter_change", %{"values" => values, "filter-type" => filter_type}, socket) do
    case filter_type do
      "products" ->
        socket
        |> assign(
          :filters,
          Map.put(socket.assigns.filters, :selected_product_ids, parse_list_param(values))
        )

      "users" ->
        socket
        |> assign(
          :filters,
          Map.put(socket.assigns.filters, :selected_user_ids, parse_list_param(values))
        )

      _ ->
        socket
    end
    |> push_path_and_apply_filters()
  end

  @impl true
  def handle_event("clear_products_filter", _params, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:filters, Map.put(socket.assigns.filters, :selected_product_ids, []))
    )
  end

  @impl true
  def handle_event("clear_users_filter", _params, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:filters, Map.put(socket.assigns.filters, :selected_user_ids, []))
    )
  end

  @impl true
  def handle_event("set_reference_story", %{"id" => job_story_id}, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(
        :similarity_search,
        %{
          socket.assigns.similarity_search
          | reference_job_story_id: job_story_id
        }
      )
    )
  end

  @impl true
  def handle_event("clear_reference_story", _params, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(:similarity_search, %{
        socket.assigns.similarity_search
        | reference_job_story_id: nil
      })
    )
  end

  @impl true
  def handle_event("update_similarity_weights", params, socket) do
    # Handle both nested and flat parameter structures
    weights =
      case params do
        %{"weights" => weights} -> weights
        _ -> params
      end

    # Get current weights and update only the changed one
    current_weights = socket.assigns.similarity_search.weights

    updated_weights =
      case weights do
        %{"situation" => situation} ->
          %{current_weights | situation: parse_float(situation, current_weights.situation)}

        %{"motivation" => motivation} ->
          %{current_weights | motivation: parse_float(motivation, current_weights.motivation)}

        %{"outcome" => outcome} ->
          %{current_weights | outcome: parse_float(outcome, current_weights.outcome)}

        _ ->
          current_weights
      end

    # Normalize weights to sum to 1.0
    total = updated_weights.situation + updated_weights.motivation + updated_weights.outcome

    normalized_weights = %{
      situation: updated_weights.situation / total,
      motivation: updated_weights.motivation / total,
      outcome: updated_weights.outcome / total
    }

    push_path_and_apply_filters(
      socket
      |> assign(
        :similarity_search,
        %{socket.assigns.similarity_search | weights: normalized_weights}
      )
    )
  end

  @impl true
  def handle_event("update_min_scores", params, socket) do
    # Handle both nested and flat parameter structures
    min_scores =
      case params do
        %{"min_scores" => min_scores} -> min_scores
        _ -> params
      end

    # Get current min_scores and update only the changed one
    current_min_scores = socket.assigns.similarity_search.min_scores

    updated_min_scores =
      case min_scores do
        %{"situation" => situation} ->
          %{
            current_min_scores
            | situation: parse_percentage(situation, current_min_scores.situation)
          }

        %{"motivation" => motivation} ->
          %{
            current_min_scores
            | motivation: parse_percentage(motivation, current_min_scores.motivation)
          }

        %{"outcome" => outcome} ->
          %{current_min_scores | outcome: parse_percentage(outcome, current_min_scores.outcome)}

        _ ->
          current_min_scores
      end

    push_path_and_apply_filters(
      socket
      |> assign(
        :similarity_search,
        %{socket.assigns.similarity_search | min_scores: updated_min_scores}
      )
    )
  end

  @impl true
  def handle_event("update_sort_by", %{"sort_by" => sort_by}, socket) do
    push_path_and_apply_filters(
      socket
      |> assign(
        :similarity_search,
        %{socket.assigns.similarity_search | sort_by: String.to_existing_atom(sort_by)}
      )
    )
  end

  @impl true
  def handle_event("toggle_advanced_controls", _params, socket) do
    new_advanced_state = !socket.assigns.similarity_search.show_advanced_controls

    push_path_and_apply_filters(
      socket
      |> assign(
        :similarity_search,
        %{socket.assigns.similarity_search | show_advanced_controls: new_advanced_state}
      )
    )
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => "products", "item_id" => item_id},
        socket
      ) do
    current_ids = socket.assigns.filters.selected_product_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    push_path_and_apply_filters(
      socket
      |> assign(:filters, %{socket.assigns.filters | selected_product_ids: new_ids})
    )
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => "users", "item_id" => item_id},
        socket
      ) do
    current_ids = socket.assigns.filters.selected_user_ids

    new_ids =
      if item_id in current_ids do
        List.delete(current_ids, item_id)
      else
        [item_id | current_ids]
      end

    push_path_and_apply_filters(
      socket
      |> assign(:filters, %{socket.assigns.filters | selected_user_ids: new_ids})
    )
  end

  @impl true
  def handle_event(
        "toggle_filter",
        %{"filter_type" => _filter_type, "item_id" => _item_id},
        socket
      ) do
    push_path_and_apply_filters(socket)
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

  defp parse_weights_params(nil), do: %{situation: 0.4, motivation: 0.3, outcome: 0.3}
  defp parse_weights_params(""), do: %{situation: 0.4, motivation: 0.3, outcome: 0.3}

  defp parse_weights_params(param) when is_binary(param) do
    param
    |> String.split(",")
    |> Enum.map(&String.to_float/1)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {value, index}, acc ->
      case index do
        0 -> Map.put(acc, :situation, value)
        1 -> Map.put(acc, :motivation, value)
        2 -> Map.put(acc, :outcome, value)
      end
    end)
  end

  defp parse_weights_params(param) when is_list(param) do
    param
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {value, index}, acc ->
      case index do
        0 -> Map.put(acc, :situation, value)
        1 -> Map.put(acc, :motivation, value)
        2 -> Map.put(acc, :outcome, value)
      end
    end)
  end

  defp parse_weights_params(_), do: %{situation: 0.4, motivation: 0.3, outcome: 0.3}

  defp parse_min_scores_params(nil), do: %{situation: 0, motivation: 0, outcome: 0}
  defp parse_min_scores_params(""), do: %{situation: 0, motivation: 0, outcome: 0}

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
  defp parse_sort_by_param(""), do: :overall

  defp parse_sort_by_param(sort_by) when is_binary(sort_by) do
    case sort_by do
      "situation" -> :situation
      "motivation" -> :motivation
      "outcome" -> :outcome
      _ -> :overall
    end
  end

  defp parse_sort_by_param(_), do: :overall

  defp parse_percentage(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_percentage(value, _default) when is_number(value), do: value
  defp parse_percentage(_, default), do: default

  defp parse_float(value, default) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _ -> default
    end
  end

  defp parse_float(value, _default) when is_number(value), do: value
  defp parse_float(_, default), do: default

  def build_filter_params(filters, similarity_search) do
    %{}
    |> maybe_add_param(:search, filters[:search_term] || filters["search_term"], &(&1 != ""))
    |> maybe_add_param(
      :product_ids,
      filters[:selected_product_ids] || filters["selected_product_ids"],
      &(&1 != []),
      &Enum.join(&1, ",")
    )
    |> maybe_add_param(
      :user_ids,
      filters[:selected_user_ids] || filters["selected_user_ids"],
      &(&1 != []),
      &Enum.join(&1, ",")
    )
    |> maybe_add_param(
      :reference_job_story_id,
      similarity_search[:reference_job_story_id] || similarity_search["reference_job_story_id"],
      &(&1 != nil)
    )
    |> maybe_add_param(
      :weights,
      similarity_search[:weights] || similarity_search["weights"],
      &(&1 != nil),
      &format_weights/1
    )
    |> maybe_add_param(
      :min_scores,
      similarity_search[:min_scores] || similarity_search["min_scores"],
      &(&1 != nil),
      &format_min_scores/1
    )
    |> maybe_add_param(
      :sort_by,
      similarity_search[:sort_by] || similarity_search["sort_by"],
      &(&1 != nil),
      &to_string/1
    )
  end

  # Helper function to conditionally add parameters
  defp maybe_add_param(params, key, value, condition) when is_function(condition, 1) do
    if condition.(value), do: Map.put(params, key, value), else: params
  end

  defp maybe_add_param(params, key, value, condition, formatter)
       when is_function(condition, 1) and is_function(formatter, 1) do
    if condition.(value), do: Map.put(params, key, formatter.(value)), else: params
  end

  # Helper functions for formatting specific parameter types
  defp format_weights(weights) do
    "#{weights.situation},#{weights.motivation},#{weights.outcome}"
  end

  defp format_min_scores(min_scores) do
    "#{min_scores.situation},#{min_scores.motivation},#{min_scores.outcome}"
  end

  # Helper functions for similarity score formatting and display
  def format_similarity_score(similarity) do
    percentage = (similarity * 100) |> Float.round(1)
    "#{percentage}%"
  end

  def get_component_color(score) when score >= 0.8, do: "bg-green-100 text-green-800"
  def get_component_color(score) when score >= 0.6, do: "bg-yellow-100 text-yellow-800"
  def get_component_color(_score), do: "bg-red-100 text-red-800"

  # Helper function for formatting dates
  def format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  # Calculate similarity details for a job story against the reference story
  defp calculate_similarity_details(job_story, reference_job_story, weights) do
    if job_story.id == reference_job_story.id do
      # This is the reference story itself
      %{situation: 1.0, motivation: 1.0, outcome: 1.0, overall: 1.0}
    else
      # Calculate similarity using the embeddings service
      target_embeddings =
        Storyteller.JobStories.JobStory.get_component_embeddings(reference_job_story)

      job_story_embeddings = Storyteller.JobStories.JobStory.get_component_embeddings(job_story)

      if has_valid_embeddings?(target_embeddings) and has_valid_embeddings?(job_story_embeddings) do
        Storyteller.Embeddings.calculate_component_similarities(
          target_embeddings,
          job_story_embeddings,
          weights
        )
      else
        %{situation: 0.0, motivation: 0.0, outcome: 0.0, overall: 0.0}
      end
    end
  end

  # Check if embeddings are valid
  defp has_valid_embeddings?(embeddings) do
    embeddings.situation != nil and embeddings.motivation != nil and embeddings.outcome != nil
  end
end
