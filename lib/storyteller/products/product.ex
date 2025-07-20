defmodule Storyteller.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :description, :string

    many_to_many :job_stories, Storyteller.JobStories.JobStory,
      join_through: "job_stories_products",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> maybe_put_job_stories_assoc(attrs)
  end

  defp maybe_put_job_stories_assoc(changeset, %{job_stories: job_stories})
       when is_list(job_stories) do
    put_assoc(changeset, :job_stories, job_stories)
  end

  defp maybe_put_job_stories_assoc(changeset, _), do: changeset
end
