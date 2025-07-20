defmodule Storyteller.Products.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :type, Ecto.Enum, values: [:number, :salesforce]
    field :pseudonym, :string

    many_to_many :markets, Storyteller.Products.Market,
      join_through: "users_markets",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:pseudonym, :type])
    |> validate_required([:pseudonym, :type])
    |> put_assoc(:markets, (attrs["market_ids"] || attrs[:market_ids]) |> get_markets())
  end

  defp get_markets(market_ids) do
    case market_ids do
      ids when is_list(ids) ->
        if Enum.empty?(ids) do
          []
        else
          Storyteller.Products.list_markets_by_ids(ids)
        end

      _ ->
        []
    end
  end
end
