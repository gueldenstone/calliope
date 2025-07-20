defmodule Storyteller.JobStories.JobStory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_stories" do
    field :title, :string
    field :situation, :string
    field :motivation, :string
    field :outcome, :string

    # Embedding fields for each component
    field :situation_embedding, :binary
    field :motivation_embedding, :binary
    field :outcome_embedding, :binary
    field :embeddings_updated_at, :utc_datetime

    many_to_many :products, Storyteller.Products.Product,
      join_through: "job_stories_products",
      on_replace: :delete

    many_to_many :users, Storyteller.Products.User,
      join_through: "job_stories_users",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job_story, attrs) do
    job_story
    |> cast(attrs, [:title, :situation, :motivation, :outcome])
    |> validate_required([:title, :situation, :motivation, :outcome])
    |> put_assoc(:products, (attrs["product_ids"] || attrs[:product_ids]) |> get_products())
    |> put_assoc(:users, (attrs["user_ids"] || attrs[:user_ids]) |> get_users())
  end

  @doc """
  Changeset for updating embeddings. This is used when embeddings need to be recalculated.
  """
  def embedding_changeset(job_story, embeddings) do
    job_story
    # Don't cast any fields, we'll put them manually
    |> cast(%{}, [])
    |> put_change(:situation_embedding, serialize_embedding(embeddings.situation))
    |> put_change(:motivation_embedding, serialize_embedding(embeddings.motivation))
    |> put_change(:outcome_embedding, serialize_embedding(embeddings.outcome))
    |> put_change(:embeddings_updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Serializes an Nx tensor to binary for storage in the database.
  """
  def serialize_embedding(embedding) when is_struct(embedding, Nx.Tensor) do
    Nx.serialize(embedding) |> :erlang.term_to_binary()
  end

  def serialize_embedding(nil), do: nil

  @doc """
  Deserializes a binary back to an Nx tensor for similarity calculations.
  """
  def deserialize_embedding(binary) when is_binary(binary) do
    binary |> :erlang.binary_to_term() |> Nx.deserialize()
  end

  def deserialize_embedding(nil), do: nil

  @doc """
  Checks if the job story has up-to-date embeddings.
  """
  def embeddings_up_to_date?(%__MODULE__{embeddings_updated_at: nil}), do: false

  def embeddings_up_to_date?(%__MODULE__{embeddings_updated_at: updated_at}) do
    # Consider embeddings fresh if updated within the last hour
    DateTime.diff(DateTime.utc_now(), updated_at, :hour) < 1
  end

  @doc """
  Gets the component embeddings as a map, deserializing from binary if needed.
  """
  def get_component_embeddings(%__MODULE__{} = job_story) do
    %{
      situation: deserialize_embedding(job_story.situation_embedding),
      motivation: deserialize_embedding(job_story.motivation_embedding),
      outcome: deserialize_embedding(job_story.outcome_embedding)
    }
  end

  defp get_products(product_ids) do
    case product_ids do
      ids when is_list(ids) ->
        if Enum.empty?(ids) do
          []
        else
          Storyteller.Products.list_products_by_ids(ids)
        end

      _ ->
        []
    end
  end

  defp get_users(user_ids) do
    case user_ids do
      ids when is_list(ids) ->
        if Enum.empty?(ids) do
          []
        else
          Storyteller.Products.list_users_by_ids(ids)
        end

      _ ->
        []
    end
  end
end
