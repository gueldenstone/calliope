defmodule StorytellerWeb.JobStoryLive.Similar do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories
  alias Storyteller.Embeddings

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
     |> assign(:show_advanced_controls, false)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    # Load all job stories for the left panel
    job_stories = JobStories.list_job_stories()

    {:noreply,
     socket
     |> assign(:page_title, "Explore Similar Job Stories")
     |> assign(:job_stories, job_stories)}
  end

  @impl true
  def handle_event("select_job_story", %{"id" => job_story_id}, socket) do
    # Set loading state first
    socket = assign(socket, :loading_similar, true)

    # Find the selected job story using Map.get for efficiency
    job_stories_map = Map.new(socket.assigns.job_stories, &{&1.id, &1})
    job_story = Map.get(job_stories_map, job_story_id)

    case job_story do
      selected_story ->
        # Get all other job stories for comparison
        other_stories =
          Enum.reject(socket.assigns.job_stories, fn js -> js.id == selected_story.id end)

        # Find similar stories with enhanced options
        similar_stories =
          find_similar_stories_enhanced(selected_story, other_stories, socket.assigns)

        {:noreply,
         socket
         |> assign(:selected_job_story, selected_story)
         |> assign(:similar_stories, similar_stories)
         |> assign(:loading_similar, false)}

      nil ->
        {:noreply, assign(socket, :loading_similar, false)}
    end
  end

  @impl true
  def handle_event("toggle_advanced_controls", _params, socket) do
    {:noreply, assign(socket, :show_advanced_controls, !socket.assigns.show_advanced_controls)}
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
    {:noreply, recalculate_similar_stories(socket)}
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
    {:noreply, recalculate_similar_stories(socket)}
  end

  @impl true
  def handle_event("update_sort_by", %{"sort_by" => sort_by}, socket) do
    sort_by = String.to_existing_atom(sort_by)
    socket = assign(socket, :sort_by, sort_by)
    {:noreply, recalculate_similar_stories(socket)}
  end

  @doc """
  Recalculates similar stories when advanced control parameters change.
  Only recalculates if a job story is currently selected.
  """
  defp recalculate_similar_stories(socket) do
    if socket.assigns.selected_job_story do
      other_stories =
        Enum.reject(socket.assigns.job_stories, fn js ->
          js.id == socket.assigns.selected_job_story.id
        end)

      similar_stories =
        find_similar_stories_enhanced(
          socket.assigns.selected_job_story,
          other_stories,
          socket.assigns
        )

      assign(socket, :similar_stories, similar_stories)
    else
      socket
    end
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
end
