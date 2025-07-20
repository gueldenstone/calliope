defmodule Storyteller.JobStoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Storyteller.JobStories` context.
  """

  @doc """
  Generate a job_story.
  """
  def job_story_fixture(attrs \\ %{}) do
    {:ok, job_story} =
      attrs
      |> Enum.into(%{
        motivation: "some motivation",
        outcome: "some outcome",
        situation: "some situation",
        title: "some title"
      })
      |> Storyteller.JobStories.create_job_story()

    job_story
  end
end
