defmodule StorytellerWeb.JobStoryLiveTest do
  use StorytellerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Storyteller.JobStoriesFixtures

  @create_attrs %{title: "some title", situation: "some situation", motivation: "some motivation", outcome: "some outcome"}
  @update_attrs %{title: "some updated title", situation: "some updated situation", motivation: "some updated motivation", outcome: "some updated outcome"}
  @invalid_attrs %{title: nil, situation: nil, motivation: nil, outcome: nil}

  defp create_job_story(_) do
    job_story = job_story_fixture()
    %{job_story: job_story}
  end

  describe "Index" do
    setup [:create_job_story]

    test "lists all job_stories", %{conn: conn, job_story: job_story} do
      {:ok, _index_live, html} = live(conn, ~p"/job_stories")

      assert html =~ "Listing Job stories"
      assert html =~ job_story.title
    end

    test "saves new job_story", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      assert index_live |> element("a", "New Job story") |> render_click() =~
               "New Job story"

      assert_patch(index_live, ~p"/job_stories/new")

      assert index_live
             |> form("#job_story-form", job_story: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_story-form", job_story: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_stories")

      html = render(index_live)
      assert html =~ "Job story created successfully"
      assert html =~ "some title"
    end

    test "updates job_story in listing", %{conn: conn, job_story: job_story} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      assert index_live |> element("#job_stories-#{job_story.id} a", "Edit") |> render_click() =~
               "Edit Job story"

      assert_patch(index_live, ~p"/job_stories/#{job_story}/edit")

      assert index_live
             |> form("#job_story-form", job_story: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_story-form", job_story: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_stories")

      html = render(index_live)
      assert html =~ "Job story updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes job_story in listing", %{conn: conn, job_story: job_story} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      assert index_live |> element("#job_stories-#{job_story.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#job_stories-#{job_story.id}")
    end
  end

  describe "Show" do
    setup [:create_job_story]

    test "displays job_story", %{conn: conn, job_story: job_story} do
      {:ok, _show_live, html} = live(conn, ~p"/job_stories/#{job_story}")

      assert html =~ "Show Job story"
      assert html =~ job_story.title
    end

    test "updates job_story within modal", %{conn: conn, job_story: job_story} do
      {:ok, show_live, _html} = live(conn, ~p"/job_stories/#{job_story}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Job story"

      assert_patch(show_live, ~p"/job_stories/#{job_story}/show/edit")

      assert show_live
             |> form("#job_story-form", job_story: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#job_story-form", job_story: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/job_stories/#{job_story}")

      html = render(show_live)
      assert html =~ "Job story updated successfully"
      assert html =~ "some updated title"
    end
  end
end
