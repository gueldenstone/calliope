defmodule Storyteller.Products.Market do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "markets" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
