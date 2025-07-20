defmodule Storyteller.JobStories do
  @moduledoc """
  The JobStories context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Storyteller.Repo

  alias Storyteller.JobStories.JobStory

  # Centralized association definitions
  @job_story_associations [:products, :users]

  @doc """
  Returns the list of associations that should be preloaded for job stories.
  This centralizes the association definitions to prevent missing preloads.

  ## Examples

      iex> job_story_associations()
      [:products, :users]

  """
  def job_story_associations, do: @job_story_associations

  @doc """
  Returns the list of job_stories with products preloaded.

  ## Examples

      iex> list_job_stories()
      [%JobStory{products: [%Product{}, ...]}, ...]

  """
  def list_job_stories do
    JobStory
    |> preload(^@job_story_associations)
    |> Repo.all()
  end

  @doc """
  Returns the list of job_stories with filters applied.
  Supports filtering by search_term, product_ids, and user_ids.

  ## Examples

      iex> list_job_stories("user")
      [%JobStory{products: [%Product{}, ...]}, ...]

      iex> list_job_stories(%{search: "user", product_ids: ["id1", "id2"], user_ids: ["id3"]})
      [%JobStory{products: [%Product{}, ...]}, ...]

  """
  def list_job_stories(search_term) when is_binary(search_term) and search_term != "" do
    list_job_stories(%{"search" => search_term})
  end

  def list_job_stories(filters) when is_map(filters) do
    search_term = filters["search"] || filters[:search]
    product_ids = filters["product_ids"] || filters[:product_ids]
    user_ids = filters["user_ids"] || filters[:user_ids]

    query = JobStory

    # Apply search filter first
    query = filter_by_search(query, search_term)

    # Apply product filter if specified
    query =
      if product_ids && product_ids != [] do
        query
        |> join(:inner, [j], p in assoc(j, :products))
        |> where([j, p], p.id in ^product_ids)
      else
        query
      end

    # Apply user filter if specified
    query =
      if user_ids && user_ids != [] do
        # If we already have a product join, we need to handle the join differently
        if product_ids && product_ids != [] do
          query
          |> join(:inner, [j, p], u in assoc(j, :users))
          |> where([j, p, u], u.id in ^user_ids)
        else
          query
          |> join(:inner, [j], u in assoc(j, :users))
          |> where([j, u], u.id in ^user_ids)
        end
      else
        query
      end

    # Apply distinct to remove duplicates from joins
    query = distinct(query, [j], j.id)

    query
    |> preload(^@job_story_associations)
    |> Repo.all()
  end

  def list_job_stories(_), do: list_job_stories()

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, ""), do: query

  defp filter_by_search(query, search_term) do
    search_pattern = "%#{search_term}%"

    where(
      query,
      [j],
      ilike(j.title, ^search_pattern) or
        ilike(j.situation, ^search_pattern) or
        ilike(j.motivation, ^search_pattern) or
        ilike(j.outcome, ^search_pattern)
    )
  end

  @doc """
  Gets a single job_story with products preloaded.

  Raises `Ecto.NoResultsError` if the Job story does not exist.

  ## Examples

      iex> get_job_story!(123)
      %JobStory{}

      iex> get_job_story!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_story!(id) do
    Repo.get!(JobStory, id) |> Repo.preload(@job_story_associations)
  end

  @doc """
  Creates a job_story and generates embeddings for it.

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
    |> case do
      {:ok, job_story} ->
        # Generate embeddings for the new job story
        job_story_with_associations = Repo.preload(job_story, @job_story_associations)
        generate_and_store_embeddings(job_story_with_associations)

      error ->
        error
    end
  end

  @doc """
  Updates a job_story and regenerates embeddings if the text content changed.

  ## Examples

      iex> update_job_story(job_story, %{field: new_value})
      {:ok, %JobStory{}}

      iex> update_job_story(job_story, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job_story(%JobStory{} = job_story, attrs) do
    job_story_with_associations = Repo.preload(job_story, @job_story_associations)

    job_story_with_associations
    |> JobStory.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_job_story} ->
        # Check if text content changed and regenerate embeddings if needed
        if text_content_changed?(job_story_with_associations, updated_job_story) do
          generate_and_store_embeddings(updated_job_story)
        else
          {:ok, updated_job_story}
        end

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
    update_job_story_association(job_story, :products, products)
  end

  @doc """
  Associates users with a job story.

  ## Examples

      iex> associate_users_with_job_story(job_story, [user1, user2])
      {:ok, %JobStory{users: [%User{}, %User{}]}}

  """
  def associate_users_with_job_story(%JobStory{} = job_story, users) do
    update_job_story_association(job_story, :users, users)
  end

  @doc """
  Updates a single association on a job story while preserving all other associations.
  This is a generic helper that ensures all associations are properly preloaded and preserved.

  ## Examples

      iex> update_job_story_association(job_story, :products, [product1, product2])
      {:ok, %JobStory{products: [%Product{}, %Product{}]}}

  """
  def update_job_story_association(%JobStory{} = job_story, association, new_value) do
    # Get the current job story with all associations preloaded
    job_story_with_associations = Repo.preload(job_story, @job_story_associations)

    # Create a changeset that preserves all existing associations
    changeset = JobStory.changeset(job_story_with_associations, %{})

    # Update the specific association
    changeset = Ecto.Changeset.put_assoc(changeset, association, new_value)

    # Explicitly preserve all other associations
    changeset =
      Enum.reduce(@job_story_associations, changeset, fn assoc, acc_changeset ->
        if assoc != association do
          existing_value = Map.get(job_story_with_associations, assoc)
          Ecto.Changeset.put_assoc(acc_changeset, assoc, existing_value)
        else
          acc_changeset
        end
      end)

    Repo.update(changeset)
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

  @doc """
  Generates and stores embeddings for a job story.
  This function is called automatically when job stories are created or updated.
  """
  def generate_and_store_embeddings(%JobStory{} = job_story) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} ->
        case Storyteller.Embeddings.generate_job_story_component_embeddings(job_story, serving) do
          {:ok, embeddings} ->
            # Update the job story with the new embeddings
            job_story
            |> JobStory.embedding_changeset(embeddings)
            |> Repo.update()

          {:error, reason} ->
            Logger.error("Failed to generate embeddings for job story #{job_story.id}: #{reason}")
            # Return the job story without embeddings
            {:ok, job_story}
        end

      {:error, reason} ->
        Logger.error("Failed to get embeddings service: #{reason}")
        # Return the job story without embeddings
        {:ok, job_story}
    end
  end

  # Checks if the text content of a job story has changed.
  defp text_content_changed?(old_job_story, new_job_story) do
    old_job_story.situation != new_job_story.situation or
      old_job_story.motivation != new_job_story.motivation or
      old_job_story.outcome != new_job_story.outcome
  end

  @doc """
  Regenerates embeddings for all job stories that don't have up-to-date embeddings.
  This is useful for bulk updates or after model changes.
  """
  def regenerate_all_embeddings do
    # Get all job stories that need embedding updates
    associations = @job_story_associations

    job_stories =
      JobStory
      |> where([j], is_nil(j.embeddings_updated_at))
      |> or_where([j], j.embeddings_updated_at < ago(1, "hour"))
      |> preload(^associations)
      |> Repo.all()

    Logger.info("Regenerating embeddings for #{length(job_stories)} job stories")

    Enum.reduce_while(job_stories, {:ok, 0}, fn job_story, {:ok, count} ->
      case generate_and_store_embeddings(job_story) do
        {:ok, _updated_job_story} ->
          {:cont, {:ok, count + 1}}

        {:error, reason} ->
          Logger.error("Failed to regenerate embeddings for job story #{job_story.id}: #{reason}")
          {:cont, {:ok, count}}
      end
    end)
  end
end
