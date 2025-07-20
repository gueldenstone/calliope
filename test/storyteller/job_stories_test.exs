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
  end
end
