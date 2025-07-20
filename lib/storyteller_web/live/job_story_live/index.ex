defmodule StorytellerWeb.JobStoryLive.Index do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories
  alias Storyteller.JobStories.JobStory

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_term, "")
     |> stream(:job_stories, JobStories.list_job_stories())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_term = params["search"] || ""

    {:noreply,
     socket
     |> assign(:search_term, search_term)
     |> stream(:job_stories, JobStories.list_job_stories(search_term), reset: true)
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
  def handle_info({StorytellerWeb.JobStoryLive.FormComponent, {:saved, job_story}}, socket) do
    # Reload the job story with products for display
    job_story_with_products = JobStories.get_job_story!(job_story.id)
    {:noreply, stream_insert(socket, :job_stories, job_story_with_products, at: -1)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job_story = JobStories.get_job_story!(id)
    {:ok, _} = JobStories.delete_job_story(job_story)

    {:noreply, stream_delete(socket, :job_stories, job_story)}
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term}, socket) do
    {:noreply, push_patch(socket, to: ~p"/job_stories?#{%{search: search_term}}")}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/job_stories")}
  end
end
