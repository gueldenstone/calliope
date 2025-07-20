defmodule Storyteller.Repo.Migrations.AddEmbeddingsToJobStories do
  use Ecto.Migration

  def change do
    alter table(:job_stories) do
      # Add embedding fields for each component
      # Using :binary type to store the embedding vectors as binary data
      add :situation_embedding, :binary
      add :motivation_embedding, :binary
      add :outcome_embedding, :binary

      # Add a flag to track if embeddings are up to date
      add :embeddings_updated_at, :utc_datetime
    end

    # Create indexes for better performance when querying embeddings
    create index(:job_stories, [:embeddings_updated_at])
  end
end
