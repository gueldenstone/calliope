defmodule Storyteller.Embeddings do
  @moduledoc """
  Service for generating text embeddings and performing similarity search.

  This module uses Bumblebee and NX to create embeddings from job stories
  and perform similarity search operations.
  """

  require Logger

  # Model configuration
  @model_name "mlx-community/nomicai-modernbert-embed-base-4bit"
  @max_text_length 512

  @doc """
  Initializes the embedding model and tokenizer.
  Returns {:ok, {model_info, tokenizer, serving}} or {:error, reason}
  """
  def init_embeddings do
    try do
      # Set the global backend to EMLX
      Nx.global_default_backend(EMLX.Backend)

      # Load the model
      {:ok, model_info} =
        Bumblebee.load_model({:hf, @model_name},
          module: Bumblebee.Text.Bert
        )

      # Load the tokenizer
      {:ok, tokenizer} =
        Bumblebee.load_tokenizer({:hf, @model_name},
          type: :bert
        )

      # Create the serving
      serving = Bumblebee.Text.text_embedding(model_info, tokenizer)

      Logger.info("Embeddings service initialized successfully")
      {:ok, {model_info, tokenizer, serving}}
    rescue
      e ->
        Logger.error("Failed to initialize embeddings service: #{inspect(e)}")
        {:error, "Failed to initialize embeddings service"}
    end
  end

  @doc """
  Generates an embedding for a given text with improved handling for short texts.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_embedding(text, serving) when is_binary(text) do
    try do
      # Improve short text handling
      processed_text = preprocess_text(text)

      # Truncate text if it's too long
      truncated_text = String.slice(processed_text, 0, @max_text_length)

      embedding = Nx.Serving.run(serving, truncated_text)
      {:ok, embedding.embedding}
    rescue
      e ->
        Logger.error("Failed to generate embedding: #{inspect(e)}")
        {:error, "Failed to generate embedding"}
    end
  end

  @doc """
  Generates an embedding for a job story by combining its fields.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_job_story_embedding(job_story, serving) do
    # Combine job story fields into a single text
    text = build_job_story_text(job_story)
    generate_embedding(text, serving)
  end

  @doc """
  Computes the cosine similarity between two embeddings.
  Returns a float between -1 and 1, where 1 is most similar.
  """
  def cosine_similarity(embedding1, embedding2) do
    try do
      # Ensure embeddings are 1D vectors
      embedding1 = Nx.flatten(embedding1)
      embedding2 = Nx.flatten(embedding2)

      # Compute dot product
      dot_product = Nx.dot(embedding1, embedding2)

      # Compute L2 norms
      norm1 = Nx.LinAlg.norm(embedding1)
      norm2 = Nx.LinAlg.norm(embedding2)

      # Avoid division by zero with small epsilon
      epsilon = 1.0e-8
      denominator = Nx.add(Nx.multiply(norm1, norm2), epsilon)

      # Compute cosine similarity
      similarity = Nx.divide(dot_product, denominator)

      # Clamp to valid range [-1, 1] to handle numerical errors
      similarity = Nx.clip(similarity, -1.0, 1.0)

      Nx.to_number(similarity)
    rescue
      e ->
        Logger.error("Failed to compute cosine similarity: #{inspect(e)}")
        0.0
    end
  end

  @doc """
  Computes the Euclidean distance-based similarity between two embeddings.
  Returns a float between 0 and 1, where 1 is most similar.
  This can work better for short texts than cosine similarity.
  """
  def euclidean_similarity(embedding1, embedding2) do
    try do
      # Ensure embeddings are 1D vectors
      embedding1 = Nx.flatten(embedding1)
      embedding2 = Nx.flatten(embedding2)

      # Compute Euclidean distance
      diff = Nx.subtract(embedding1, embedding2)
      distance = Nx.LinAlg.norm(diff)

      # Convert to similarity (higher = more similar)
      # Use a scaling factor to make the similarity more meaningful
      max_possible_distance = Nx.add(Nx.LinAlg.norm(embedding1), Nx.LinAlg.norm(embedding2))
      similarity = Nx.subtract(1.0, Nx.divide(distance, max_possible_distance))

      # Clamp to valid range [0, 1]
      similarity = Nx.clip(similarity, 0.0, 1.0)

      Nx.to_number(similarity)
    rescue
      e ->
        Logger.error("Failed to compute euclidean similarity: #{inspect(e)}")
        0.0
    end
  end

  @doc """
  Finds the most similar job stories to a given query text.
  Returns a list of {job_story, similarity_score} tuples, sorted by similarity.
  """
  def find_similar_job_stories(query_text, job_stories, serving, limit \\ 10) do
    case generate_embedding(query_text, serving) do
      {:ok, query_embedding} ->
        job_stories
        |> Enum.map(fn job_story ->
          case generate_job_story_embedding(job_story, serving) do
            {:ok, job_story_embedding} ->
              similarity = cosine_similarity(query_embedding, job_story_embedding)
              {job_story, similarity}

            {:error, _} ->
              {job_story, 0.0}
          end
        end)
        |> Enum.sort_by(fn {_job_story, similarity} -> similarity end, :desc)
        |> Enum.take(limit)

      {:error, _} ->
        Logger.error("Failed to generate query embedding")
        []
    end
  end

  @doc """
  Finds the most similar job stories to a given job story.
  Returns a list of {job_story, similarity_score} tuples, sorted by similarity.
  """
  def find_similar_to_job_story(target_job_story, job_stories, serving, limit \\ 10) do
    case generate_job_story_embedding(target_job_story, serving) do
      {:ok, target_embedding} ->
        job_stories
        |> Enum.reject(fn job_story -> job_story.id == target_job_story.id end)
        |> Enum.map(fn job_story ->
          case generate_job_story_embedding(job_story, serving) do
            {:ok, job_story_embedding} ->
              similarity = cosine_similarity(target_embedding, job_story_embedding)
              {job_story, similarity}

            {:error, _} ->
              {job_story, 0.0}
          end
        end)
        |> Enum.sort_by(fn {_job_story, similarity} -> similarity end, :desc)
        |> Enum.take(limit)

      {:error, _} ->
        Logger.error("Failed to generate target job story embedding")
        []
    end
  end

  @doc """
  Builds a text representation of a job story by combining its fields.
  """
  def build_job_story_text(job_story) do
    [
      "Title: #{job_story.title}",
      "Story:",
      "When #{job_story.situation},",
      "I want to #{job_story.motivation},",
      "so that #{job_story.outcome}."
    ]
    |> Enum.join(" ")
  end

  @doc """
  Formats a similarity score as a percentage.
  """
  def format_similarity_score(similarity) do
    percentage = (similarity * 100) |> Float.round(1)
    "#{percentage}%"
  end

  # Convenience functions that use the EmbeddingsService

  @doc """
  Generates an embedding for a given text using the service.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_embedding(text) when is_binary(text) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} ->
        generate_embedding(text, serving)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generates an embedding for a job story using the service.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_job_story_embedding(job_story) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} ->
        generate_job_story_embedding(job_story, serving)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Finds similar job stories to a query using the service.
  Returns a list of {job_story, similarity_score} tuples.
  """
  def find_similar_job_stories_service(query_text, job_stories, limit \\ 10) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} ->
        find_similar_job_stories(query_text, job_stories, serving, limit)

      {:error, reason} ->
        Logger.error("Failed to get embeddings service: #{reason}")
        []
    end
  end

  @doc """
  Finds similar job stories to a given job story using the service.
  Returns a list of {job_story, similarity_score} tuples.
  """
  def find_similar_to_job_story_service(target_job_story, job_stories, limit \\ 10) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} ->
        find_similar_to_job_story(target_job_story, job_stories, serving, limit)

      {:error, reason} ->
        Logger.error("Failed to get embeddings service: #{reason}")
        []
    end
  end

  @doc """
  Checks if the embeddings service is ready.
  """
  def ready? do
    Storyteller.EmbeddingsService.ready?()
  end

  # Add this private function
  defp preprocess_text(text) do
    text
    |> String.trim()
    # Normalize whitespace
    |> String.replace(~r/\s+/, " ")
    |> then(fn t ->
      # For very short texts, add some context
      if String.length(t) < 10 do
        "Text: #{t}"
      else
        t
      end
    end)
  end
end

defmodule SimilarityTest do
  def test_similarities do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    # Very different texts should have low similarity
    text1 = "user authentication system"
    text2 = "database migration tools"

    # Similar texts should have high similarity
    text3 = "user login system"
    text4 = "authentication and login"

    # Generate embeddings
    embedding1 = Nx.Serving.run(serving, text1)
    embedding2 = Nx.Serving.run(serving, text2)
    embedding3 = Nx.Serving.run(serving, text3)
    embedding4 = Nx.Serving.run(serving, text4)

    # Debug: Check embedding shapes and norms
    IO.puts("Embedding shapes:")
    IO.puts("  embedding1: #{inspect(Nx.shape(embedding1.embedding))}")
    IO.puts("  embedding2: #{inspect(Nx.shape(embedding2.embedding))}")

    IO.puts("Embedding norms:")
    norm1 = Nx.LinAlg.norm(embedding1.embedding) |> Nx.to_number()
    norm2 = Nx.LinAlg.norm(embedding2.embedding) |> Nx.to_number()
    IO.puts("  norm1: #{norm1}")
    IO.puts("  norm2: #{norm2}")

    # Test similarities
    sim_different =
      Storyteller.Embeddings.cosine_similarity(embedding1.embedding, embedding2.embedding)

    sim_similar =
      Storyteller.Embeddings.cosine_similarity(embedding3.embedding, embedding4.embedding)

    IO.puts("Different texts similarity: #{sim_different}")
    IO.puts("Similar texts similarity: #{sim_similar}")

    # Test with more extreme examples
    text5 = "apple fruit"
    text6 = "quantum physics"
    embedding5 = Nx.Serving.run(serving, text5)
    embedding6 = Nx.Serving.run(serving, text6)

    sim_extreme =
      Storyteller.Embeddings.cosine_similarity(embedding5.embedding, embedding6.embedding)

    IO.puts("Extreme different similarity: #{sim_extreme}")

    # Test with identical text
    sim_identical =
      Storyteller.Embeddings.cosine_similarity(embedding1.embedding, embedding1.embedding)

    IO.puts("Identical text similarity: #{sim_identical}")
  end

  def test_both_metrics do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    text1 = "cooking a steak with asparagus"
    text2 = "database migration tools"
    text3 = "user login system"
    text4 = "authentication and login"

    embedding1 = Nx.Serving.run(serving, text1)
    embedding2 = Nx.Serving.run(serving, text2)
    embedding3 = Nx.Serving.run(serving, text3)
    embedding4 = Nx.Serving.run(serving, text4)

    IO.puts("=== Cosine Similarity ===")

    sim_cos_diff =
      Storyteller.Embeddings.cosine_similarity(embedding1.embedding, embedding2.embedding)

    sim_cos_sim =
      Storyteller.Embeddings.cosine_similarity(embedding3.embedding, embedding4.embedding)

    IO.puts("Different: #{sim_cos_diff}")
    IO.puts("Similar: #{sim_cos_sim}")

    IO.puts("=== Euclidean Similarity ===")

    sim_euc_diff =
      Storyteller.Embeddings.euclidean_similarity(embedding1.embedding, embedding2.embedding)

    sim_euc_sim =
      Storyteller.Embeddings.euclidean_similarity(embedding3.embedding, embedding4.embedding)

    IO.puts("Different: #{sim_euc_diff}")
    IO.puts("Similar: #{sim_euc_sim}")
  end

  def test_with_real_data do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    # Get some real job stories
    job_stories = Storyteller.JobStories.list_job_stories()

    if length(job_stories) >= 2 do
      story1 = List.first(job_stories)
      # take the second story
      story2 = List.first(List.delete_at(job_stories, 0))

      text1 = Storyteller.Embeddings.build_job_story_text(story1)
      text2 = Storyteller.Embeddings.build_job_story_text(story2)

      embedding1 = Nx.Serving.run(serving, text1)
      embedding2 = Nx.Serving.run(serving, text2)

      sim_cosine =
        Storyteller.Embeddings.cosine_similarity(embedding1.embedding, embedding2.embedding)

      sim_euclidean =
        Storyteller.Embeddings.euclidean_similarity(embedding1.embedding, embedding2.embedding)

      IO.puts("Real job stories similarity:")
      IO.puts("  Cosine: #{sim_cosine}")
      IO.puts("  Euclidean: #{sim_euclidean}")
      IO.puts("  Story 1: #{String.slice(text1, 0, 100)}...")
      IO.puts("  Story 2: #{String.slice(text2, 0, 100)}...")
    else
      IO.puts("Need at least 2 job stories in the database to test")
    end
  end

  def test_model_quality do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    # Test with completely different domains
    texts = [
      "user authentication system",
      "database migration tools",
      "apple fruit",
      "quantum physics",
      "cooking recipe",
      "sports equipment"
    ]

    embeddings =
      Enum.map(texts, fn text ->
        Nx.Serving.run(serving, text)
      end)

    IO.puts("=== Model Quality Test ===")
    IO.puts("Testing similarity between completely different domains:")

    # Compare first text with all others
    base_embedding = List.first(embeddings)
    base_text = List.first(texts)

    Enum.zip(texts, embeddings)
    |> Enum.each(fn {text, embedding} ->
      sim =
        Storyteller.Embeddings.cosine_similarity(base_embedding.embedding, embedding.embedding)

      IO.puts("  '#{base_text}' vs '#{text}': #{sim}")
    end)
  end
end
