defmodule StorytellerWeb.JobStoryLive.FormComponent do
  use StorytellerWeb, :live_component

  alias Storyteller.JobStories

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
        <:actions>
          <.button phx-disable-with="Saving...">Save Job story</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{job_story: job_story} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(JobStories.change_job_story(job_story))
     end)}
  end

  @impl true
  def handle_event("validate", %{"job_story" => job_story_params}, socket) do
    changeset = JobStories.change_job_story(socket.assigns.job_story, job_story_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"job_story" => job_story_params}, socket) do
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
