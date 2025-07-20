defmodule Storyteller.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias Storyteller.Repo

  alias Storyteller.Products.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Returns the list of products with job stories preloaded.

  ## Examples

      iex> list_products_with_job_stories()
      [%Product{job_stories: [%JobStory{}, ...]}, ...]

  """
  def list_products_with_job_stories do
    Product
    |> preload(:job_stories)
    |> Repo.all()
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Gets a single product with job stories preloaded.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product_with_job_stories!(123)
      %Product{job_stories: [%JobStory{}, ...]}

      iex> get_product_with_job_stories!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product_with_job_stories!(id) do
    Product
    |> preload(:job_stories)
    |> Repo.get!(id)
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  @doc """
  Associates job stories with a product.

  ## Examples

      iex> associate_job_stories_with_product(product, [job_story1, job_story2])
      {:ok, %Product{job_stories: [%JobStory{}, %JobStory{}]}}

  """
  def associate_job_stories_with_product(%Product{} = product, job_stories) do
    product
    |> Repo.preload(:job_stories)
    |> Product.changeset(%{job_stories: job_stories})
    |> Repo.update()
  end

  @doc """
  Gets products by job story.

  ## Examples

      iex> get_products_by_job_story(job_story)
      [%Product{}, ...]

  """
  def get_products_by_job_story(job_story) do
    Product
    |> join(:inner, [p], j in assoc(p, :job_stories))
    |> where([p, j], j.id == ^job_story.id)
    |> Repo.all()
  end

  @doc """
  Gets products by their IDs.

  ## Examples

      iex> list_products_by_ids(["id1", "id2"])
      [%Product{}, ...]

  """
  def list_products_by_ids(ids) when is_list(ids) do
    Product
    |> where([p], p.id in ^ids)
    |> Repo.all()
  end
end
