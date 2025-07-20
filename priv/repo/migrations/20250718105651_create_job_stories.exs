defmodule Storyteller.Repo.Migrations.CreateJobStories do
  use Ecto.Migration

  def change do
    create table(:job_stories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :situation, :text
      add :motivation, :text
      add :outcome, :text

      timestamps(type: :utc_datetime)
    end
  end
end
