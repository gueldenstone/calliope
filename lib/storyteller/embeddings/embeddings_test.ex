defmodule Storyteller.ManualEmbeddingsTest do
  defp format_similarity_score(similarity) do
    percentage = (similarity * 100) |> Float.round(1)
    "#{percentage}%"
  end

  def test_component_similarities do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    # Create test job stories with different component similarities
    job_story1 = %{
      id: "1",
      title: "User Authentication System",
      situation: "users need to securely log into the application",
      motivation: "implement secure authentication",
      outcome: "users can safely access their accounts"
    }

    job_story2 = %{
      id: "2",
      title: "Login System Implementation",
      situation: "users need to access the platform",
      motivation: "provide secure login functionality",
      outcome: "users can authenticate and access the system"
    }

    job_story3 = %{
      id: "3",
      title: "Database Migration Tool",
      situation: "we need to upgrade our database schema",
      motivation: "safely migrate data without downtime",
      outcome: "database is upgraded with all data preserved"
    }

    # Test component-based similarity
    IO.puts("=== Component-Based Similarity Test ===")

    # show the user stories without stopwords
    IO.puts("=== User Stories Without Stopwords ===")
    IO.puts("Job Story 1: #{Storyteller.Embeddings.preprocess_text(job_story1.situation)}")
    IO.puts("Job Story 2: #{Storyteller.Embeddings.preprocess_text(job_story2.situation)}")
    IO.puts("Job Story 3: #{Storyteller.Embeddings.preprocess_text(job_story3.situation)}")

    # Compare similar stories (should have high similarity in all components)
    similar_stories =
      Storyteller.Embeddings.find_similar_to_job_story(
        job_story1,
        [job_story2, job_story3],
        serving,
        2
      )

    Enum.each(similar_stories, fn {story, details} ->
      IO.puts("Similar to '#{job_story1.title}':")
      IO.puts("  Story: #{story.title}")
      IO.puts("  Situation: #{format_similarity_score(details.situation)}")
      IO.puts("  Motivation: #{format_similarity_score(details.motivation)}")
      IO.puts("  Outcome: #{format_similarity_score(details.outcome)}")
      IO.puts("  Overall: #{format_similarity_score(details.overall)}")
      IO.puts("")
    end)
  end

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

  def test_stopword_filtering do
    IO.puts("=== Stopword Filtering Test ===")

    test_texts = [
      "I am setting up a sound system for the venue",
      "Setting up sound system venue",
      "The users need to access the application securely",
      "Users need access application securely",
      "We are implementing a very secure authentication system",
      "Implementing secure authentication system"
    ]

    Enum.each(test_texts, fn text ->
      processed = Storyteller.Embeddings.preprocess_text(text)
      IO.puts("Original: '#{text}'")
      IO.puts("Processed: '#{processed}'")
      IO.puts("")
    end)
  end

  def test_similarity_with_stopwords do
    {:ok, serving} = Storyteller.EmbeddingsService.get_serving()

    IO.puts("=== Similarity Comparison with Stopword Filtering ===")

    # Test pairs with and without stopwords
    test_pairs = [
      {
        "I am setting up a sound system for the venue",
        "Setting up sound system venue"
      },
      {
        "The users need to access the application securely",
        "Users need access application securely"
      },
      {
        "We are implementing a very secure authentication system",
        "Implementing secure authentication system"
      }
    ]

    Enum.each(test_pairs, fn {text1, text2} ->
      # Generate embeddings for original texts
      embedding1 = Nx.Serving.run(serving, text1)
      embedding2 = Nx.Serving.run(serving, text2)

      # Generate embeddings for processed texts
      processed1 = Storyteller.Embeddings.preprocess_text(text1)
      processed2 = Storyteller.Embeddings.preprocess_text(text2)

      embedding1_processed = Nx.Serving.run(serving, processed1)
      embedding2_processed = Nx.Serving.run(serving, processed2)

      # Calculate similarities
      sim_original =
        Storyteller.Embeddings.cosine_similarity(embedding1.embedding, embedding2.embedding)

      sim_processed =
        Storyteller.Embeddings.cosine_similarity(
          embedding1_processed.embedding,
          embedding2_processed.embedding
        )

      IO.puts("Text 1: '#{text1}'")
      IO.puts("Text 2: '#{text2}'")
      IO.puts("Processed 1: '#{processed1}'")
      IO.puts("Processed 2: '#{processed2}'")
      IO.puts("Original similarity: #{format_similarity_score(sim_original)}")
      IO.puts("Processed similarity: #{format_similarity_score(sim_processed)}")
      IO.puts("Improvement: #{((sim_processed - sim_original) * 100) |> Float.round(1)}%")
      IO.puts("")
    end)
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
