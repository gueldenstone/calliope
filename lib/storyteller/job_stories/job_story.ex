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

    many_to_many :products, Storyteller.Products.Product,
      join_through: "job_stories_products",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job_story, attrs) do
    job_story
    |> cast(attrs, [:title, :situation, :motivation, :outcome])
    |> validate_required([:title, :situation, :motivation, :outcome])
    |> put_assoc(:products, (attrs["product_ids"] || attrs[:product_ids]) |> get_products())
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
end
