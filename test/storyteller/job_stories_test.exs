defmodule Storyteller.JobStoriesTest do
  use Storyteller.DataCase

  alias Storyteller.JobStories

  describe "job_stories" do
    alias Storyteller.JobStories.JobStory

    import Storyteller.JobStoriesFixtures

    @invalid_attrs %{title: nil, situation: nil, motivation: nil, outcome: nil}

    test "list_job_stories/0 returns all job_stories" do
      job_story = job_story_fixture()
      assert JobStories.list_job_stories() == [job_story]
    end

    test "get_job_story!/1 returns the job_story with given id" do
      job_story = job_story_fixture()
      assert JobStories.get_job_story!(job_story.id) == job_story
    end

    test "create_job_story/1 with valid data creates a job_story" do
      valid_attrs = %{title: "some title", situation: "some situation", motivation: "some motivation", outcome: "some outcome"}

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
      update_attrs = %{title: "some updated title", situation: "some updated situation", motivation: "some updated motivation", outcome: "some updated outcome"}

      assert {:ok, %JobStory{} = job_story} = JobStories.update_job_story(job_story, update_attrs)
      assert job_story.title == "some updated title"
      assert job_story.situation == "some updated situation"
      assert job_story.motivation == "some updated motivation"
      assert job_story.outcome == "some updated outcome"
    end

    test "update_job_story/2 with invalid data returns error changeset" do
      job_story = job_story_fixture()
      assert {:error, %Ecto.Changeset{}} = JobStories.update_job_story(job_story, @invalid_attrs)
      assert job_story == JobStories.get_job_story!(job_story.id)
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
  end
end
