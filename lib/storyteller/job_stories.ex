defmodule Storyteller.JobStories do
  @moduledoc """
  The JobStories context.
  """

  import Ecto.Query, warn: false
  alias Storyteller.Repo

  alias Storyteller.JobStories.JobStory

  @doc """
  Returns the list of job_stories.

  ## Examples

      iex> list_job_stories()
      [%JobStory{}, ...]

  """
  def list_job_stories do
    Repo.all(JobStory)
  end

  @doc """
  Returns the list of job_stories filtered by search term.

  ## Examples

      iex> list_job_stories("user")
      [%JobStory{}, ...]

  """
  def list_job_stories(search_term) when is_binary(search_term) and search_term != "" do
    search_pattern = "%#{search_term}%"

    JobStory
    |> where(
      [j],
      ilike(j.title, ^search_pattern) or
        ilike(j.situation, ^search_pattern) or
        ilike(j.motivation, ^search_pattern) or
        ilike(j.outcome, ^search_pattern)
    )
    |> Repo.all()
  end

  def list_job_stories(_), do: list_job_stories()

  @doc """
  Gets a single job_story.

  Raises `Ecto.NoResultsError` if the Job story does not exist.

  ## Examples

      iex> get_job_story!(123)
      %JobStory{}

      iex> get_job_story!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_story!(id), do: Repo.get!(JobStory, id)

  @doc """
  Creates a job_story.

  ## Examples

      iex> create_job_story(%{field: value})
      {:ok, %JobStory{}}

      iex> create_job_story(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job_story(attrs \\ %{}) do
    %JobStory{}
    |> JobStory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a job_story.

  ## Examples

      iex> update_job_story(job_story, %{field: new_value})
      {:ok, %JobStory{}}

      iex> update_job_story(job_story, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job_story(%JobStory{} = job_story, attrs) do
    job_story
    |> JobStory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a job_story.

  ## Examples

      iex> delete_job_story(job_story)
      {:ok, %JobStory{}}

      iex> delete_job_story(job_story)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job_story(%JobStory{} = job_story) do
    Repo.delete(job_story)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job_story changes.

  ## Examples

      iex> change_job_story(job_story)
      %Ecto.Changeset{data: %JobStory{}}

  """
  def change_job_story(%JobStory{} = job_story, attrs \\ %{}) do
    JobStory.changeset(job_story, attrs)
  end
end
