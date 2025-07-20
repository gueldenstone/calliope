defmodule Storyteller.JobStoriesTest do
  use Storyteller.DataCase

  alias Storyteller.JobStories

  describe "job_stories" do
    alias Storyteller.JobStories.JobStory

    import Storyteller.JobStoriesFixtures
    import Storyteller.ProductsFixtures

    @invalid_attrs %{title: nil, situation: nil, motivation: nil, outcome: nil}

    test "list_job_stories/0 returns all job_stories" do
      job_story = job_story_fixture()
      job_stories = JobStories.list_job_stories()
      assert length(job_stories) == 1
      [retrieved_job_story] = job_stories
      assert retrieved_job_story.id == job_story.id
      assert retrieved_job_story.products == []
    end

    test "get_job_story!/1 returns the job_story with given id" do
      job_story = job_story_fixture()
      retrieved_job_story = JobStories.get_job_story!(job_story.id)
      assert retrieved_job_story.id == job_story.id
      assert retrieved_job_story.products == []
    end

    test "create_job_story/1 with valid data creates a job_story" do
      valid_attrs = %{
        title: "some title",
        situation: "some situation",
        motivation: "some motivation",
        outcome: "some outcome"
      }

      assert {:ok, %JobStory{} = job_story} = JobStories.create_job_story(valid_attrs)
      assert job_story.title == "some title"
      assert job_story.situation == "some situation"
      assert job_story.motivation == "some motivation"
      assert job_story.outcome == "some outcome"
    end

    test "create_job_story/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = JobStories.create_job_story(@invalid_attrs)
    end

    test "update_job_story/2 with valid data updates the job_story" do
      job_story = job_story_fixture()

      update_attrs = %{
        title: "some updated title",
        situation: "some updated situation",
        motivation: "some updated motivation",
        outcome: "some updated outcome"
      }

      assert {:ok, %JobStory{} = job_story} = JobStories.update_job_story(job_story, update_attrs)
      assert job_story.title == "some updated title"
      assert job_story.situation == "some updated situation"
      assert job_story.motivation == "some updated motivation"
      assert job_story.outcome == "some updated outcome"
    end

    test "update_job_story/2 with invalid data returns error changeset" do
      job_story = job_story_fixture()
      assert {:error, %Ecto.Changeset{}} = JobStories.update_job_story(job_story, @invalid_attrs)
      retrieved_job_story = JobStories.get_job_story!(job_story.id)
      assert retrieved_job_story.id == job_story.id
      assert retrieved_job_story.products == []
    end

    test "delete_job_story/1 deletes the job_story" do
      job_story = job_story_fixture()
      assert {:ok, %JobStory{}} = JobStories.delete_job_story(job_story)
      assert_raise Ecto.NoResultsError, fn -> JobStories.get_job_story!(job_story.id) end
    end

    test "change_job_story/1 returns a job_story changeset" do
      job_story = job_story_fixture()
      assert %Ecto.Changeset{} = JobStories.change_job_story(job_story)
    end

    test "job_story with product associations" do
      # Create a product first
      product = product_fixture()

      # Create a job story with product associations
      job_story_attrs = %{
        product_ids: [product.id],
        title: "Test Job Story",
        situation: "test situation",
        motivation: "test motivation",
        outcome: "test outcome"
      }

      assert {:ok, job_story} = JobStories.create_job_story(job_story_attrs)

      # Reload to get products
      job_story_with_products = JobStories.get_job_story!(job_story.id)
      assert length(job_story_with_products.products) == 1
      assert hd(job_story_with_products.products).id == product.id

      # Verify it can be retrieved with products
      retrieved_job_story = JobStories.get_job_story!(job_story.id)
      assert length(retrieved_job_story.products) == 1
      assert hd(retrieved_job_story.products).id == product.id
    end

    test "list_job_stories/1 with search term filters correctly" do
      job_story1 = job_story_fixture(%{title: "User Authentication", situation: "login process"})
      job_story2 = job_story_fixture(%{title: "Data Export", situation: "export process"})

      # Search by title
      results = JobStories.list_job_stories("User")
      assert length(results) == 1
      assert hd(results).id == job_story1.id

      # Search by situation
      results = JobStories.list_job_stories("export")
      assert length(results) == 1
      assert hd(results).id == job_story2.id
    end

    test "list_job_stories/1 with product filter works correctly" do
      product1 = product_fixture(%{name: "Product A"})
      product2 = product_fixture(%{name: "Product B"})

      job_story1 = job_story_fixture(%{product_ids: [product1.id]})
      job_story2 = job_story_fixture(%{product_ids: [product2.id]})
      job_story3 = job_story_fixture(%{product_ids: [product1.id, product2.id]})

      # Filter by product1
      results = JobStories.list_job_stories(%{"product_ids" => [product1.id]})
      assert length(results) == 2
      assert Enum.any?(results, fn js -> js.id == job_story1.id end)
      assert Enum.any?(results, fn js -> js.id == job_story3.id end)

      # Filter by product2
      results = JobStories.list_job_stories(%{"product_ids" => [product2.id]})
      assert length(results) == 2
      assert Enum.any?(results, fn js -> js.id == job_story2.id end)
      assert Enum.any?(results, fn js -> js.id == job_story3.id end)
    end

    test "list_job_stories/1 with combined filters works correctly" do
      product = product_fixture(%{name: "Test Product"})
      user = user_fixture(%{pseudonym: "Test User"})

      # Create job story first
      job_story_attrs = %{
        title: "User Login",
        situation: "test situation",
        motivation: "test motivation",
        outcome: "test outcome"
      }

      {:ok, job_story1} = JobStories.create_job_story(job_story_attrs)

      # Associate products separately
      JobStories.associate_products_with_job_story(job_story1, [product])

      # Create another job story without the search term
      _job_story2 =
        job_story_fixture(%{
          title: "Data Export",
          product_ids: [product.id]
        })

      # Associate users with job stories
      JobStories.associate_users_with_job_story(job_story1, [user])

      # Filter by product and search term
      results =
        JobStories.list_job_stories(%{
          "search" => "Login",
          "product_ids" => [product.id]
        })

      assert length(results) == 1
      assert hd(results).id == job_story1.id
    end

    test "list_job_stories/1 with multiple products uses OR logic" do
      product1 = product_fixture(%{name: "Product A"})
      product2 = product_fixture(%{name: "Product B"})

      # Create job story associated with product1
      job_story1 = job_story_fixture(%{product_ids: [product1.id]})

      # Create job story associated with product2
      job_story2 = job_story_fixture(%{product_ids: [product2.id]})

      # Create job story associated with both products
      job_story3 = job_story_fixture(%{product_ids: [product1.id, product2.id]})

      # Filter by both products - should return all 3 job stories (OR logic)
      results = JobStories.list_job_stories(%{"product_ids" => [product1.id, product2.id]})

      assert length(results) == 3
      assert Enum.any?(results, fn js -> js.id == job_story1.id end)
      assert Enum.any?(results, fn js -> js.id == job_story2.id end)
      assert Enum.any?(results, fn js -> js.id == job_story3.id end)
    end

    test "list_job_stories/1 with multiple users uses OR logic" do
      user1 = user_fixture(%{pseudonym: "User A"})
      user2 = user_fixture(%{pseudonym: "User B"})

      # Create job story associated with user1
      job_story1 = job_story_fixture()
      JobStories.associate_users_with_job_story(job_story1, [user1])

      # Create job story associated with user2
      job_story2 = job_story_fixture()
      JobStories.associate_users_with_job_story(job_story2, [user2])

      # Create job story associated with both users
      job_story3 = job_story_fixture()
      JobStories.associate_users_with_job_story(job_story3, [user1, user2])

      # Filter by both users - should return all 3 job stories (OR logic)
      results = JobStories.list_job_stories(%{"user_ids" => [user1.id, user2.id]})

      assert length(results) == 3
      assert Enum.any?(results, fn js -> js.id == job_story1.id end)
      assert Enum.any?(results, fn js -> js.id == job_story2.id end)
      assert Enum.any?(results, fn js -> js.id == job_story3.id end)
    end

    test "list_job_stories/1 with both product and user filters (AND logic)" do
      product = product_fixture(%{name: "Test Product"})
      user = user_fixture(%{pseudonym: "Test User"})

      # Create a job story with both product and user
      job_story = job_story_fixture(%{product_ids: [product.id]})
      {:ok, job_story_with_users} = JobStories.associate_users_with_job_story(job_story, [user])
      job_story = job_story_with_users

      # Create another job story with only the product
      _job_story_product_only = job_story_fixture(%{product_ids: [product.id]})

      # Create another job story with only the user
      job_story_user_only = job_story_fixture()
      JobStories.associate_users_with_job_story(job_story_user_only, [user])

      # Filter by both product and user - should return only the job story with both
      results =
        JobStories.list_job_stories(%{
          "product_ids" => [product.id],
          "user_ids" => [user.id]
        })

      assert length(results) == 1
      assert hd(results).id == job_story.id
    end
  end
end
