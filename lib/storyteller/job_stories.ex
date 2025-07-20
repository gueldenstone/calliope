defmodule Storyteller.JobStories do
  @moduledoc """
  The JobStories context.
  """

  import Ecto.Query, warn: false
  alias Storyteller.Repo

  alias Storyteller.JobStories.JobStory

  @doc """
  Returns the list of job_stories with products preloaded.

  ## Examples

      iex> list_job_stories()
      [%JobStory{products: [%Product{}, ...]}, ...]

  """
  def list_job_stories do
    JobStory
    |> preload([:products, :users])
    |> Repo.all()
  end

  @doc """
  Returns the list of job_stories filtered by search term with products preloaded.

  ## Examples

      iex> list_job_stories("user")
      [%JobStory{products: [%Product{}, ...]}, ...]

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
    |> preload([:products, :users])
    |> Repo.all()
  end

  def list_job_stories(_), do: list_job_stories()

  @doc """
  Gets a single job_story with products preloaded.

  Raises `Ecto.NoResultsError` if the Job story does not exist.

  ## Examples

      iex> get_job_story!(123)
      %JobStory{products: [%Product{}, ...]}

      iex> get_job_story!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_story!(id) do
    JobStory
    |> preload([:products, :users])
    |> Repo.get!(id)
  end

  @doc """
  Creates a job_story.

  ## Examples

      iex> create_job_story(%{field: value})
      {:ok, %JobStory{}}

      iex> create_job_story(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job_story(attrs \\ %{}) do
    case %JobStory{}
         |> JobStory.changeset(attrs)
         |> Repo.insert() do
      {:ok, job_story} ->
        # Reload with products preloaded
        {:ok, get_job_story!(job_story.id)}

      error ->
        error
    end
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
    case job_story
         |> JobStory.changeset(attrs)
         |> Repo.update() do
      {:ok, job_story} ->
        # Reload with products preloaded
        {:ok, get_job_story!(job_story.id)}

      error ->
        error
    end
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

  @doc """
  Associates products with a job story.

  ## Examples

      iex> associate_products_with_job_story(job_story, [product1, product2])
      {:ok, %JobStory{products: [%Product{}, %Product{}]}}

  """
  def associate_products_with_job_story(%JobStory{} = job_story, products) do
    job_story
    |> Repo.preload(:products)
    |> JobStory.changeset(%{products: products})
    |> Repo.update()
  end

  @doc """
  Gets job stories by product.

  ## Examples

      iex> get_job_stories_by_product(product)
      [%JobStory{}, ...]

  """
  def get_job_stories_by_product(product) do
    JobStory
    |> join(:inner, [j], p in assoc(j, :products))
    |> where([j, p], p.id == ^product.id)
    |> Repo.all()
  end

  @doc """
  Gets job stories by their IDs.

  ## Examples

      iex> list_job_stories_by_ids(["id1", "id2"])
      [%JobStory{}, ...]

  """
  def list_job_stories_by_ids(ids) when is_list(ids) do
    JobStory
    |> where([j], j.id in ^ids)
    |> Repo.all()
  end
end
