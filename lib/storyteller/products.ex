defmodule Storyteller.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias Storyteller.Repo

  alias Storyteller.Products.Product

  # Centralized association definitions
  @product_associations [:job_stories]
  @market_associations [:users]
  @user_associations [:markets, :job_stories]

  @doc """
  Returns the list of associations that should be preloaded for products.
  """
  def product_associations, do: @product_associations

  @doc """
  Returns the list of associations that should be preloaded for markets.
  """
  def market_associations, do: @market_associations

  @doc """
  Returns the list of associations that should be preloaded for users.
  """
  def user_associations, do: @user_associations

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
    |> preload(^@product_associations)
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
    |> preload(^@product_associations)
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
    update_product_association(product, :job_stories, job_stories)
  end

  @doc """
  Updates a single association on a product while preserving all other associations.
  """
  def update_product_association(%Product{} = product, association, new_value) do
    # Get the current product with all associations preloaded
    product_with_associations = Repo.preload(product, @product_associations)

    # Create a changeset that preserves all existing associations
    changeset = Product.changeset(product_with_associations, %{})

    # Update the specific association
    changeset = Ecto.Changeset.put_assoc(changeset, association, new_value)

    # Explicitly preserve all other associations
    changeset =
      Enum.reduce(@product_associations, changeset, fn assoc, acc_changeset ->
        if assoc != association do
          existing_value = Map.get(product_with_associations, assoc)
          Ecto.Changeset.put_assoc(acc_changeset, assoc, existing_value)
        else
          acc_changeset
        end
      end)

    Repo.update(changeset)
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

  alias Storyteller.Products.Market

  @doc """
  Returns the list of markets.

  ## Examples

      iex> list_markets()
      [%Market{}, ...]

  """
  def list_markets do
    Market
    |> preload(^@market_associations)
    |> Repo.all()
  end

  @doc """
  Gets a single market.

  Raises `Ecto.NoResultsError` if the Market does not exist.

  ## Examples

      iex> get_market!(123)
      %Market{}

      iex> get_market!(456)
      ** (Ecto.NoResultsError)

  """
  def get_market!(id) do
    Market
    |> preload(^@market_associations)
    |> Repo.get!(id)
  end

  @doc """
  Creates a market.

  ## Examples

      iex> create_market(%{field: value})
      {:ok, %Market{}}

      iex> create_market(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_market(attrs \\ %{}) do
    %Market{}
    |> Market.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a market.

  ## Examples

      iex> update_market(market, %{field: new_value})
      {:ok, %Market{}}

      iex> update_market(market, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_market(%Market{} = market, attrs) do
    market
    |> Market.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a market.

  ## Examples

      iex> delete_market(market)
      {:ok, %Market{}}

      iex> delete_market(market)
      {:error, %Ecto.Changeset{}}

  """
  def delete_market(%Market{} = market) do
    Repo.delete(market)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking market changes.

  ## Examples

      iex> change_market(market)
      %Ecto.Changeset{data: %Market{}}

  """
  def change_market(%Market{} = market, attrs \\ %{}) do
    Market.changeset(market, attrs)
  end

  @doc """
  Associates users with a market.

  ## Examples

      iex> associate_users_with_market(market, [user1, user2])
      {:ok, %Market{users: [%User{}, %User{}]}}

  """
  def associate_users_with_market(%Market{} = market, users) do
    update_market_association(market, :users, users)
  end

  @doc """
  Updates a single association on a market while preserving all other associations.
  """
  def update_market_association(%Market{} = market, association, new_value) do
    # Get the current market with all associations preloaded
    market_with_associations = Repo.preload(market, @market_associations)

    # Create a changeset that preserves all existing associations
    changeset = Market.changeset(market_with_associations, %{})

    # Update the specific association
    changeset = Ecto.Changeset.put_assoc(changeset, association, new_value)

    # Explicitly preserve all other associations
    changeset =
      Enum.reduce(@market_associations, changeset, fn assoc, acc_changeset ->
        if assoc != association do
          existing_value = Map.get(market_with_associations, assoc)
          Ecto.Changeset.put_assoc(acc_changeset, assoc, existing_value)
        else
          acc_changeset
        end
      end)

    Repo.update(changeset)
  end

  alias Storyteller.Products.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    User
    |> preload(^@user_associations)
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    User
    |> preload(^@user_associations)
    |> Repo.get!(id)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Associates markets with a user.

  ## Examples

      iex> associate_markets_with_user(user, [market1, market2])
      {:ok, %User{markets: [%Market{}, %Market{}]}}

  """
  def associate_markets_with_user(%User{} = user, markets) do
    update_user_association(user, :markets, markets)
  end

  @doc """
  Associates job stories with a user.

  ## Examples

      iex> associate_job_stories_with_user(user, [job_story1, job_story2])
      {:ok, %User{job_stories: [%JobStory{}, %JobStory{}]}}

  """
  def associate_job_stories_with_user(%User{} = user, job_stories) do
    update_user_association(user, :job_stories, job_stories)
  end

  @doc """
  Updates a single association on a user while preserving all other associations.
  """
  def update_user_association(%User{} = user, association, new_value) do
    # Get the current user with all associations preloaded
    user_with_associations = Repo.preload(user, @user_associations)

    # Create a changeset that preserves all existing associations
    changeset = User.changeset(user_with_associations, %{})

    # Update the specific association
    changeset = Ecto.Changeset.put_assoc(changeset, association, new_value)

    # Explicitly preserve all other associations
    changeset =
      Enum.reduce(@user_associations, changeset, fn assoc, acc_changeset ->
        if assoc != association do
          existing_value = Map.get(user_with_associations, assoc)
          Ecto.Changeset.put_assoc(acc_changeset, assoc, existing_value)
        else
          acc_changeset
        end
      end)

    Repo.update(changeset)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Gets users by their IDs.

  ## Examples

      iex> list_users_by_ids(["id1", "id2"])
      [%User{}, ...]

  """
  def list_users_by_ids(ids) when is_list(ids) do
    User
    |> where([u], u.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Gets markets by their IDs.

  ## Examples

      iex> list_markets_by_ids(["id1", "id2"])
      [%Market{}, ...]

  """
  def list_markets_by_ids(ids) when is_list(ids) do
    Market
    |> where([m], m.id in ^ids)
    |> Repo.all()
  end
end
