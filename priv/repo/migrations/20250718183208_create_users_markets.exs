defmodule Storyteller.Repo.Migrations.CreateUsersMarkets do
  use Ecto.Migration

  def change do
    create table(:users_markets, primary_key: false) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :market_id, references(:markets, type: :binary_id, on_delete: :delete_all)
    end

    create index(:users_markets, [:user_id])
    create index(:users_markets, [:market_id])
    create unique_index(:users_markets, [:user_id, :market_id])
  end
end
