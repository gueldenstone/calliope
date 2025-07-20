defmodule Storyteller.EmbeddingsTest do
  use Storyteller.DataCase

  alias Storyteller.Embeddings
  alias Storyteller.JobStories
  alias Storyteller.Products

  # Test data
  @sample_job_story %{
    title: "User Authentication System",
    situation: "Users need to securely log into the application",
    motivation: "Security is critical for protecting user data",
    outcome: "Implemented OAuth2 with JWT tokens and 2FA support"
  }

  @sample_query "I need to implement user authentication and security features"

  setup do
    # Initialize embeddings service for tests
    {:ok, {_model_info, _tokenizer, serving}} = Embeddings.init_embeddings()

    # Create test data
    {:ok, product} =
      Products.create_product(%{name: "Test Product", description: "A test product"})

    {:ok, user} = Products.create_user(%{type: :number, pseudonym: "test_user"})

    {:ok, job_story} =
      JobStories.create_job_story(%{
        title: @sample_job_story.title,
        situation: @sample_job_story.situation,
        motivation: @sample_job_story.motivation,
        outcome: @sample_job_story.outcome,
        product_ids: [product.id],
        user_ids: [user.id]
      })

    {:ok, %{serving: serving, job_story: job_story, product: product, user: user}}
  end

  describe "init_embeddings/0" do
    test "initializes the embeddings service successfully" do
      assert {:ok, {model_info, tokenizer, serving}} = Embeddings.init_embeddings()
      assert is_map(model_info)
      assert is_map(tokenizer)
      assert is_struct(serving, Nx.Serving)
    end
  end

  describe "generate_embedding/2" do
    test "generates embeddings for text", %{serving: serving} do
      text = "This is a test of the embedding generation system"

      assert {:ok, embedding} = Embeddings.generate_embedding(text, serving)
      assert Nx.shape(embedding) == {768}
      assert Nx.type(embedding) == {:f, 32}
    end

    test "handles empty text", %{serving: serving} do
      assert {:ok, embedding} = Embeddings.generate_embedding("", serving)
      assert Nx.shape(embedding) == {768}
    end

    test "truncates long text", %{serving: serving} do
      long_text = String.duplicate("This is a very long text that should be truncated. ", 100)

      assert {:ok, embedding} = Embeddings.generate_embedding(long_text, serving)
      assert Nx.shape(embedding) == {768}
    end
  end

  describe "generate_job_story_embedding/2" do
    test "generates embeddings for job stories", %{serving: serving, job_story: job_story} do
      assert {:ok, embedding} = Embeddings.generate_job_story_embedding(job_story, serving)
      assert Nx.shape(embedding) == {768}
      assert Nx.type(embedding) == {:f, 32}
    end

    test "combines all job story fields", %{serving: _serving, job_story: job_story} do
      expected_text =
        "Title: #{job_story.title} Story: When #{job_story.situation}, I want to #{job_story.motivation}, so that #{job_story.outcome}."

      # Test that the text building function works correctly
      assert Embeddings.build_job_story_text(job_story) == expected_text
    end
  end

  describe "cosine_similarity/2" do
    test "computes cosine similarity between embeddings", %{serving: serving} do
      text1 = "user authentication system"
      text2 = "login and security features"

      {:ok, embedding1} = Embeddings.generate_embedding(text1, serving)
      {:ok, embedding2} = Embeddings.generate_embedding(text2, serving)

      # Test that similarity computation works
      similarity = Embeddings.cosine_similarity(embedding1, embedding2)

      # Verify the similarity is a valid number between -1 and 1
      assert is_float(similarity)
      assert similarity >= -1.0
      assert similarity <= 1.0
      # Should be positive for similar texts
      assert similarity > 0.0
    end

    test "handles identical embeddings", %{serving: serving} do
      text = "test text"
      {:ok, embedding} = Embeddings.generate_embedding(text, serving)

      similarity = Embeddings.cosine_similarity(embedding, embedding)
      # Should be very close to 1.0
      assert similarity > 0.99
    end

    test "handles zero vectors gracefully", %{serving: _serving} do
      # Create zero tensors
      zero_tensor = Nx.broadcast(0.0, {768})

      similarity = Embeddings.cosine_similarity(zero_tensor, zero_tensor)
      assert similarity == 0.0
    end
  end

  describe "find_similar_job_stories/4" do
    test "finds similar job stories for a query", %{serving: serving, job_story: job_story} do
      job_stories = [job_story]
      query = @sample_query

      similar_stories = Embeddings.find_similar_job_stories(query, job_stories, serving, 5)

      assert length(similar_stories) == 1
      {found_job_story, similarity} = hd(similar_stories)
      assert found_job_story.id == job_story.id
      assert similarity > 0.0
      assert similarity <= 1.0
    end

    test "returns empty list when no job stories provided", %{serving: serving} do
      similar_stories = Embeddings.find_similar_job_stories(@sample_query, [], serving, 5)
      assert similar_stories == []
    end

    test "limits results to specified count", %{serving: serving, job_story: job_story} do
      job_stories = [job_story]

      similar_stories =
        Embeddings.find_similar_job_stories(@sample_query, job_stories, serving, 1)

      assert length(similar_stories) == 1

      similar_stories =
        Embeddings.find_similar_job_stories(@sample_query, job_stories, serving, 10)

      # Only one job story available
      assert length(similar_stories) == 1
    end
  end

  describe "find_similar_to_job_story/4" do
    test "finds similar job stories to a given job story", %{
      serving: serving,
      job_story: job_story
    } do
      job_stories = [job_story]

      similar_stories = Embeddings.find_similar_to_job_story(job_story, job_stories, serving, 5)

      # Should return empty list since there's only one job story
      # and it excludes the target job story
      assert similar_stories == []
    end

    test "excludes the target job story from results", %{serving: serving, job_story: job_story} do
      # Create a second job story
      {:ok, product} =
        Products.create_product(%{name: "Another Product", description: "Another test product"})

      {:ok, user} = Products.create_user(%{type: :salesforce, pseudonym: "another_user"})

      {:ok, job_story2} =
        JobStories.create_job_story(%{
          title: "Another Job Story",
          situation: "Another situation",
          motivation: "Another motivation",
          outcome: "Another outcome",
          product_ids: [product.id],
          user_ids: [user.id]
        })

      job_stories = [job_story, job_story2]

      similar_stories = Embeddings.find_similar_to_job_story(job_story, job_stories, serving, 5)

      assert length(similar_stories) == 1
      {found_job_story, _similarity} = hd(similar_stories)
      assert found_job_story.id == job_story2.id
      assert found_job_story.id != job_story.id
    end
  end

  describe "find_similar_to_job_story_enhanced/4" do
    test "finds similar job stories with custom weights", %{
      serving: serving,
      job_story: job_story
    } do
      # Create a second job story
      {:ok, product} =
        Products.create_product(%{name: "Another Product", description: "Another test product"})

      {:ok, user} = Products.create_user(%{type: :salesforce, pseudonym: "another_user"})

      {:ok, job_story2} =
        JobStories.create_job_story(%{
          title: "Another Job Story",
          situation: "Another situation",
          motivation: "Another motivation",
          outcome: "Another outcome",
          product_ids: [product.id],
          user_ids: [user.id]
        })

      job_stories = [job_story, job_story2]

      # Test with custom weights
      opts = [
        weights: %{situation: 0.6, motivation: 0.2, outcome: 0.2},
        limit: 5
      ]

      similar_stories =
        Embeddings.find_similar_to_job_story_enhanced(job_story, job_stories, serving, opts)

      assert length(similar_stories) == 1
      {found_job_story, similarity_details} = hd(similar_stories)
      assert found_job_story.id == job_story2.id
      assert found_job_story.id != job_story.id
      assert Map.has_key?(similarity_details, :situation)
      assert Map.has_key?(similarity_details, :motivation)
      assert Map.has_key?(similarity_details, :outcome)
      assert Map.has_key?(similarity_details, :overall)
    end

    test "filters by minimum scores", %{serving: serving, job_story: job_story} do
      # Create a second job story
      {:ok, product} =
        Products.create_product(%{name: "Another Product", description: "Another test product"})

      {:ok, user} = Products.create_user(%{type: :salesforce, pseudonym: "another_user"})

      {:ok, job_story2} =
        JobStories.create_job_story(%{
          title: "Another Job Story",
          situation: "Another situation",
          motivation: "Another motivation",
          outcome: "Another outcome",
          product_ids: [product.id],
          user_ids: [user.id]
        })

      job_stories = [job_story, job_story2]

      # Test with very high minimum scores as percentages (should filter out results)
      opts = [
        min_scores: %{situation: 99, motivation: 99, outcome: 99},
        limit: 5
      ]

      similar_stories =
        Embeddings.find_similar_to_job_story_enhanced(job_story, job_stories, serving, opts)

      # Should return empty list due to very high minimum scores
      assert similar_stories == []
    end

    test "sorts by different components", %{serving: serving, job_story: job_story} do
      # Create multiple job stories
      {:ok, product} =
        Products.create_product(%{name: "Another Product", description: "Another test product"})

      {:ok, user} = Products.create_user(%{type: :salesforce, pseudonym: "another_user"})

      {:ok, job_story2} =
        JobStories.create_job_story(%{
          title: "Another Job Story",
          situation: "Another situation",
          motivation: "Another motivation",
          outcome: "Another outcome",
          product_ids: [product.id],
          user_ids: [user.id]
        })

      {:ok, job_story3} =
        JobStories.create_job_story(%{
          title: "Third Job Story",
          situation: "Third situation",
          motivation: "Third motivation",
          outcome: "Third outcome",
          product_ids: [product.id],
          user_ids: [user.id]
        })

      job_stories = [job_story, job_story2, job_story3]

      # Test sorting by situation
      opts = [sort_by: :situation, limit: 5]

      similar_stories =
        Embeddings.find_similar_to_job_story_enhanced(job_story, job_stories, serving, opts)

      assert length(similar_stories) == 2
      # Results should be sorted by situation similarity (descending)
      [{_first_story, first_scores}, {_second_story, second_scores}] = similar_stories
      assert first_scores.situation >= second_scores.situation
    end
  end

  describe "format_similarity_score/1" do
    test "formats similarity scores as percentages" do
      assert Embeddings.format_similarity_score(0.5) == "50.0%"
      assert Embeddings.format_similarity_score(0.123) == "12.3%"
      assert Embeddings.format_similarity_score(1.0) == "100.0%"
      assert Embeddings.format_similarity_score(0.0) == "0.0%"
    end
  end

  describe "build_job_story_text/1" do
    test "builds text representation of job story", %{job_story: job_story} do
      expected_text =
        "Title: #{job_story.title} Story: When #{job_story.situation}, I want to #{job_story.motivation}, so that #{job_story.outcome}."

      assert Embeddings.build_job_story_text(job_story) == expected_text
    end
  end

  describe "preprocess_text/1" do
    test "removes stopwords and normalizes text" do
      assert Embeddings.preprocess_text("I am setting up a sound system") ==
               "am setting sound system"

      assert Embeddings.preprocess_text("The Users Need Access") == "users need access"
      assert Embeddings.preprocess_text("users, need, access!") == "users need access"
      assert Embeddings.preprocess_text("users   need    access") == "users need access"
    end

    test "preserves important technical terms" do
      assert Embeddings.preprocess_text("implement secure authentication system") ==
               "implement secure authentication system"

      # Test with more complex technical text
      result = Embeddings.preprocess_text("I am implementing a very secure authentication system")
      assert result == "am implementing secure authentication system"

      result = Embeddings.preprocess_text("We need to upgrade the database schema")
      assert result == "need upgrade database schema"
    end

    test "handles empty and very short texts" do
      assert Embeddings.preprocess_text("") == "Text: "
      assert Embeddings.preprocess_text("a") == "Text: "
      assert Embeddings.preprocess_text("the") == "Text: "
      assert Embeddings.preprocess_text("setup") == "Text: setup"
    end
  end
end
