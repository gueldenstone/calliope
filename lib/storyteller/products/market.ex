defmodule Storyteller.Products.Market do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "markets" do
    field :name, :string

    many_to_many :users, Storyteller.Products.User,
      join_through: "users_markets",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_assoc(:users, (attrs["user_ids"] || attrs[:user_ids]) |> get_users())
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
