defmodule Storyteller.Products.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :type, Ecto.Enum, values: [:number, :salesforce]
    field :pseudonym, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:pseudonym, :type])
    |> validate_required([:pseudonym, :type])
  end
end
