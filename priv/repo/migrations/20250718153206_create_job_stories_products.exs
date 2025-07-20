defmodule Storyteller.Repo.Migrations.CreateJobStoriesProducts do
  use Ecto.Migration

  def change do
    create table(:job_stories_products, primary_key: false) do
      add :job_story_id, references(:job_stories, type: :binary_id, on_delete: :delete_all),
        null: false

      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all),
        null: false
    end

    create index(:job_stories_products, [:job_story_id])
    create index(:job_stories_products, [:product_id])

    create unique_index(:job_stories_products, [:job_story_id, :product_id],
             name: :job_stories_products_unique_index
           )
  end
end
