defmodule Storyteller.Embeddings do
  @moduledoc """
  Service for generating text embeddings and performing similarity search.

  This module provides functionality for:
  - Generating embeddings for text and job stories
  - Computing similarity between embeddings
  - Finding similar job stories using component-based similarity
  - Text preprocessing and stopword removal

  The module uses stored embeddings for performance and only generates
  new embeddings when creating or updating job stories.
  """

  require Logger

  # Model configuration
  @model_name "mlx-community/nomicai-modernbert-embed-base-4bit"
  @max_text_length 512

  # Default component weights for similarity calculations
  @default_weights %{situation: 0.4, motivation: 0.3, outcome: 0.3}

  # Common English stopwords that don't add semantic meaning
  @stopwords MapSet.new([
               # Articles
               "a",
               "an",
               "the",
               # Prepositions
               "in",
               "on",
               "at",
               "to",
               "for",
               "of",
               "with",
               "by",
               "from",
               "up",
               "about",
               "into",
               "through",
               "during",
               "before",
               "after",
               "above",
               "below",
               "between",
               "among",
               # Conjunctions
               "and",
               "or",
               "but",
               "nor",
               "yet",
               "so",
               "if",
               "because",
               "although",
               "while",
               "where",
               "when",
               "why",
               "how",
               # Pronouns
               "i",
               "you",
               "he",
               "she",
               "it",
               "we",
               "they",
               "me",
               "him",
               "her",
               "us",
               "them",
               "my",
               "your",
               "his",
               "her",
               "its",
               "our",
               "their",
               "mine",
               "yours",
               "his",
               "hers",
               "ours",
               "theirs",
               # Common verbs (basic forms)
               "is",
               "are",
               "was",
               "were",
               "be",
               "been",
               "being",
               "have",
               "has",
               "had",
               "do",
               "does",
               "did",
               "will",
               "would",
               "could",
               "should",
               "may",
               "might",
               "must",
               "can",
               # Common adverbs
               "very",
               "really",
               "quite",
               "just",
               "only",
               "also",
               "too",
               "as",
               "well",
               "even",
               "still",
               "again",
               "ever",
               "never",
               "always",
               "often",
               "sometimes",
               "usually",
               "rarely",
               "seldom",
               # Common adjectives
               "good",
               "bad",
               "big",
               "small",
               "new",
               "old",
               "high",
               "low",
               "long",
               "short",
               "great",
               "little",
               "much",
               "many",
               "few",
               "some",
               "any",
               "all",
               "each",
               "every",
               "other",
               "another",
               "such",
               "same",
               "different",
               # Numbers and quantifiers
               "one",
               "two",
               "three",
               "first",
               "second",
               "third",
               "next",
               "last",
               "more",
               "most",
               "less",
               "least",
               "several",
               "various",
               "numerous",
               "multiple",
               # Common words in technical contexts that don't add semantic value
               "this",
               "that",
               "these",
               "those",
               "there",
               "here",
               "where",
               "when",
               "why",
               "how",
               "what",
               "which",
               "who",
               "whom",
               "whose"
             ])

  # ============================================================================
  # Public API - Core Embedding Functions
  # ============================================================================

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
  Generates an embedding for a given text.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_embedding(text, serving) when is_binary(text) do
    try do
      processed_text = preprocess_text(text)
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
  Generates an embedding for a given text using the service.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_embedding(text) when is_binary(text) do
    case Storyteller.EmbeddingsService.get_serving() do
      {:ok, serving} -> generate_embedding(text, serving)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates embeddings for each component of a job story (situation, motivation, outcome).
  Returns {:ok, %{situation: embedding, motivation: embedding, outcome: embedding}} or {:error, reason}
  """
  def generate_job_story_component_embeddings(job_story, serving) do
    try do
      situation_embedding = generate_embedding(job_story.situation, serving)
      motivation_embedding = generate_embedding(job_story.motivation, serving)
      outcome_embedding = generate_embedding(job_story.outcome, serving)

      case {situation_embedding, motivation_embedding, outcome_embedding} do
        {{:ok, situation}, {:ok, motivation}, {:ok, outcome}} ->
          {:ok, %{situation: situation, motivation: motivation, outcome: outcome}}

        _ ->
          {:error, "Failed to generate component embeddings"}
      end
    rescue
      e ->
        Logger.error("Failed to generate job story component embeddings: #{inspect(e)}")
        {:error, "Failed to generate component embeddings"}
    end
  end

  @doc """
  Generates an embedding for a job story by combining its fields.
  Returns {:ok, embedding} or {:error, reason}
  """
  def generate_job_story_embedding(job_story, serving) do
    text = build_job_story_text(job_story)
    generate_embedding(text, serving)
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

  # ============================================================================
  # Public API - Similarity Functions
  # ============================================================================

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
  Calculates similarity scores for each component and overall similarity.
  Returns %{situation: score, motivation: score, outcome: score, overall: score}
  """
  def calculate_component_similarities(target_embeddings, job_story_embeddings) do
    calculate_component_similarities(target_embeddings, job_story_embeddings, @default_weights)
  end

  def calculate_similarity(target_embedding, job_story_embedding) do
    euclidean_similarity(target_embedding, job_story_embedding)
  end

  @doc """
  Calculates similarity scores for each component and overall similarity with custom weights.
  Weights should sum to 1.0.
  Returns %{situation: score, motivation: score, outcome: score, overall: score}
  """
  def calculate_component_similarities(target_embeddings, job_story_embeddings, weights) do
    situation_sim =
      calculate_similarity(target_embeddings.situation, job_story_embeddings.situation)

    motivation_sim =
      calculate_similarity(target_embeddings.motivation, job_story_embeddings.motivation)

    outcome_sim = calculate_similarity(target_embeddings.outcome, job_story_embeddings.outcome)

    # Calculate overall similarity as weighted average
    overall_sim =
      situation_sim * (weights.situation || 0.4) +
        motivation_sim * (weights.motivation || 0.3) +
        outcome_sim * (weights.outcome || 0.3)

    %{
      situation: situation_sim,
      motivation: motivation_sim,
      outcome: outcome_sim,
      overall: overall_sim
    }
  end

  # ============================================================================
  # Public API - Job Story Similarity Search
  # ============================================================================

  @doc """
  Finds similar job stories to a given job story using component-based similarity.
  Returns a list of {job_story, similarity_details} tuples, sorted by overall similarity.
  """
  def find_similar_to_job_story(target_job_story, job_stories, _serving \\ nil, limit \\ 10) do
    target_embeddings = Storyteller.JobStories.JobStory.get_component_embeddings(target_job_story)

    if has_valid_embeddings?(target_embeddings) do
      job_stories
      |> Enum.reject(fn job_story -> job_story.id == target_job_story.id end)
      |> Enum.map(fn job_story ->
        job_story_embeddings = Storyteller.JobStories.JobStory.get_component_embeddings(job_story)

        if has_valid_embeddings?(job_story_embeddings) do
          similarity_details =
            calculate_component_similarities(target_embeddings, job_story_embeddings)

          {job_story, similarity_details}
        else
          {job_story, %{situation: 0.0, motivation: 0.0, outcome: 0.0, overall: 0.0}}
        end
      end)
      |> Enum.sort_by(fn {_job_story, details} -> details.overall end, :desc)
      |> Enum.take(limit)
    else
      Logger.warning("Target job story #{target_job_story.id} has no valid embeddings")
      []
    end
  end

  @doc """
  Finds similar job stories to a given job story using component-based similarity with filtering.
  Returns a list of {job_story, similarity_details} tuples, sorted by overall similarity.

  Options:
  - limit: maximum number of results (default: 10)
  - weights: component weights %{situation: 0.4, motivation: 0.3, outcome: 0.3}
  - min_scores: minimum similarity scores as percentages %{situation: 50, motivation: 30, outcome: 40}
  - sort_by: component to sort by (:overall, :situation, :motivation, :outcome)
  """
  def find_similar_to_job_story_enhanced(
        target_job_story,
        job_stories,
        _serving \\ nil,
        opts \\ []
      ) do
    limit = Keyword.get(opts, :limit, 10)
    weights = Keyword.get(opts, :weights, @default_weights)
    min_scores = Keyword.get(opts, :min_scores, %{})
    sort_by = Keyword.get(opts, :sort_by, :overall)

    target_embeddings = Storyteller.JobStories.JobStory.get_component_embeddings(target_job_story)

    if has_valid_embeddings?(target_embeddings) do
      job_stories
      |> Enum.reject(fn job_story -> job_story.id == target_job_story.id end)
      |> Enum.map(fn job_story ->
        job_story_embeddings = Storyteller.JobStories.JobStory.get_component_embeddings(job_story)

        if has_valid_embeddings?(job_story_embeddings) do
          similarity_details =
            calculate_component_similarities(target_embeddings, job_story_embeddings, weights)

          {job_story, similarity_details}
        else
          {job_story, %{situation: 0.0, motivation: 0.0, outcome: 0.0, overall: 0.0}}
        end
      end)
      |> filter_by_min_scores(min_scores)
      |> sort_by_component(sort_by)
      |> Enum.take(limit)
    else
      Logger.warning("Target job story #{target_job_story.id} has no valid embeddings")
      []
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
              similarity = euclidean_similarity(query_embedding, job_story_embedding)
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

  # ============================================================================
  # Public API - Service Wrapper Functions
  # ============================================================================

  @doc """
  Finds similar job stories to a given job story using the service.
  Returns a list of {job_story, similarity_details} tuples.
  """
  def find_similar_to_job_story_service(target_job_story, job_stories, limit \\ 10) do
    find_similar_to_job_story(target_job_story, job_stories, nil, limit)
  end

  @doc """
  Finds similar job stories to a given job story using enhanced component-based similarity with the service.
  Returns a list of {job_story, similarity_details} tuples.

  Options:
  - limit: maximum number of results (default: 10)
  - weights: component weights %{situation: 0.4, motivation: 0.3, outcome: 0.3}
  - min_scores: minimum similarity scores as percentages %{situation: 50, motivation: 30, outcome: 40}
  - sort_by: component to sort by (:overall, :situation, :motivation, :outcome)
  """
  def find_similar_to_job_story_enhanced_service(target_job_story, job_stories, opts \\ []) do
    find_similar_to_job_story_enhanced(target_job_story, job_stories, nil, opts)
  end

  @doc """
  Checks if the embeddings service is ready.
  """
  def ready? do
    Storyteller.EmbeddingsService.ready?()
  end

  # ============================================================================
  # Public API - Utility Functions
  # ============================================================================

  @doc """
  Preprocesses text by removing stopwords, normalizing case, and cleaning punctuation.
  """
  def preprocess_text(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/[^\w\s\-]/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.split(" ")
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&MapSet.member?(@stopwords, &1))
    |> Enum.join(" ")
    |> then(fn t ->
      if String.length(t) < 10 do
        "Text: #{t}"
      else
        t
      end
    end)
  end

  @doc """
  Formats a similarity score as a percentage.
  """
  def format_similarity_score(similarity) do
    percentage = (similarity * 100) |> Float.round(1)
    "#{percentage}%"
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  @doc """
  Filters job stories by minimum similarity scores for specific components.
  Each component is filtered independently based on its percentage score.
  min_scores should be provided as percentages (0-100).
  """
  defp filter_by_min_scores(job_stories_with_scores, min_scores) do
    Enum.filter(job_stories_with_scores, fn {_job_story, scores} ->
      Enum.all?(min_scores, fn {component, min_percentage} ->
        # Convert similarity score to percentage for comparison
        component_percentage = Map.get(scores, component, 0.0) * 100
        component_percentage >= min_percentage
      end)
    end)
  end

  defp sort_by_component(job_stories_with_scores, :overall) do
    Enum.sort_by(job_stories_with_scores, fn {_job_story, scores} -> scores.overall end, :desc)
  end

  defp sort_by_component(job_stories_with_scores, :situation) do
    Enum.sort_by(job_stories_with_scores, fn {_job_story, scores} -> scores.situation end, :desc)
  end

  defp sort_by_component(job_stories_with_scores, :motivation) do
    Enum.sort_by(job_stories_with_scores, fn {_job_story, scores} -> scores.motivation end, :desc)
  end

  defp sort_by_component(job_stories_with_scores, :outcome) do
    Enum.sort_by(job_stories_with_scores, fn {_job_story, scores} -> scores.outcome end, :desc)
  end

  defp sort_by_component(job_stories_with_scores, _),
    do: sort_by_component(job_stories_with_scores, :overall)

  defp has_valid_embeddings?(embeddings) do
    embeddings.situation != nil and
      embeddings.motivation != nil and
      embeddings.outcome != nil
  end
end
