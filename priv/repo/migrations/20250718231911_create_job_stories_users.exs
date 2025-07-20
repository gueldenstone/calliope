defmodule Storyteller.Repo.Migrations.CreateJobStoriesUsers do
  use Ecto.Migration

  def change do
    create table(:job_stories_users, primary_key: false) do
      add :job_story_id, references(:job_stories, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
    end

    create index(:job_stories_users, [:job_story_id])
    create index(:job_stories_users, [:user_id])

    create unique_index(:job_stories_users, [:job_story_id, :user_id],
             name: :job_stories_users_job_story_id_user_id_index
           )
  end
end
