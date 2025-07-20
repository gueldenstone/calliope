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

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job_story, attrs) do
    job_story
    |> cast(attrs, [:title, :situation, :motivation, :outcome])
    |> validate_required([:title, :situation, :motivation, :outcome])
  end
end
