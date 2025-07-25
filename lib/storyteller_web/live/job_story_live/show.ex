defmodule StorytellerWeb.JobStoryLive.Show do
  use StorytellerWeb, :live_view

  alias Storyteller.JobStories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:job_story, JobStories.get_job_story!(id))}
  end

  defp page_title(:show), do: "Show Job story"
  defp page_title(:edit), do: "Edit Job story"
end
