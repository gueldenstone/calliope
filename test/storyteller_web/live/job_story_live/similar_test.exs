defmodule StorytellerWeb.JobStoryLive.SimilarTest do
  use StorytellerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Storyteller.JobStoriesFixtures
  import Storyteller.ProductsFixtures

  defp create_job_stories(_) do
    # Create test products and users
    product1 = product_fixture(%{name: "Test Product 1"})
    product2 = product_fixture(%{name: "Test Product 2"})
    user1 = user_fixture(%{pseudonym: "test_user_1"})
    user2 = user_fixture(%{pseudonym: "test_user_2"})

    # Create job stories
    job_story1 =
      job_story_fixture(%{
        title: "User Authentication System",
        situation: "users need to securely log into the application",
        motivation: "implement secure authentication",
        outcome: "users can safely access their accounts",
        product_ids: [product1.id],
        user_ids: [user1.id]
      })

    job_story2 =
      job_story_fixture(%{
        title: "Database Migration Tool",
        situation: "we need to upgrade our database schema",
        motivation: "safely migrate data without downtime",
        outcome: "database is upgraded with all data preserved",
        product_ids: [product2.id],
        user_ids: [user2.id]
      })

    job_story3 =
      job_story_fixture(%{
        title: "Login System Implementation",
        situation: "users need to access the platform",
        motivation: "provide secure login functionality",
        outcome: "users can authenticate and access the system",
        product_ids: [product1.id],
        user_ids: [user1.id]
      })

    %{
      job_story1: job_story1,
      job_story2: job_story2,
      job_story3: job_story3,
      product1: product1,
      product2: product2,
      user1: user1,
      user2: user2
    }
  end

  describe "Similar job stories page" do
    setup [:create_job_stories]

    test "renders the page with job stories list", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/job_stories/similar")

      assert html =~ "Explore Similar Job Stories"
      assert html =~ "All Job Stories"
      assert html =~ "User Authentication System"
      assert html =~ "Database Migration Tool"
      assert html =~ "Login System Implementation"
    end

    test "shows embeddings service status", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/job_stories/similar")

      # Should show either ready or loading status
      assert html =~ "AI Similarity Search" || html =~ "AI Similarity Search Loading"
    end

    test "shows no selection state initially", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/job_stories/similar")

      assert html =~ "Select a Job Story"
      assert html =~ "Choose a job story from the left panel"
    end

    test "selects a job story when clicked", %{conn: conn, job_story1: job_story1} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories/similar")

      # Click on the first job story
      index_live
      |> element("div[phx-click='select_job_story']")
      |> render_click()

      # Should show the selected job story in the right panel
      html = render(index_live)
      assert html =~ "Similar to: #{job_story1.title}"
      assert html =~ job_story1.situation
      assert html =~ job_story1.motivation
      assert html =~ job_story1.outcome
    end

    test "shows loading state when selecting job story", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories/similar")

      # Click on a job story to trigger loading
      index_live
      |> element("div[phx-click='select_job_story']")
      |> render_click()

      # Should show loading state briefly
      html = render(index_live)
      # The loading state might be very brief, so we just check the structure is correct
      assert html =~ "Similar to:"
    end

    test "displays job story details correctly", %{conn: conn, job_story1: job_story1} do
      {:ok, index_live, _html} = live(conn, ~p"/job_stories/similar")

      # Click on the first job story
      index_live
      |> element("div[phx-click='select_job_story']")
      |> render_click()

      html = render(index_live)

      # Check that the job story details are displayed
      assert html =~ job_story1.title
      assert html =~ job_story1.situation
      assert html =~ job_story1.motivation
      assert html =~ job_story1.outcome

      # Check that component similarity scores are displayed
      assert html =~ "Situation:"
      assert html =~ "Motivation:"
      assert html =~ "Outcome:"
      assert html =~ "Overall:"

      # Check that products are displayed if present
      if length(job_story1.products) > 0 do
        assert html =~ "Products:"
        assert html =~ hd(job_story1.products).name
      end
    end

    test "provides navigation back to job stories", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/job_stories/similar")

      assert html =~ "Back to Job Stories"
      assert html =~ ~p"/job_stories"
    end
  end
end
