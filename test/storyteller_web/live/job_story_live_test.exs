defmodule StorytellerWeb.JobStoryLiveTest do
  use StorytellerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Storyteller.JobStoriesFixtures
  import Storyteller.ProductsFixtures

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

    test "search and filters work together", %{conn: conn} do
      # Create test data
      product1 = product_fixture(%{name: "E-commerce Platform", description: "Online store platform"})
      product2 = product_fixture(%{name: "Mobile App", description: "Mobile application"})

      user1 = user_fixture(%{pseudonym: "Sales User", type: :salesforce})
      user2 = user_fixture(%{pseudonym: "Admin User", type: :number})

      # Create job stories with different combinations
      job_story1 = job_story_fixture(%{
        title: "E-commerce Checkout",
        situation: "users reach checkout",
        motivation: "complete purchase quickly",
        outcome: "increase conversion rates",
        product_ids: [product1.id],
        user_ids: [user1.id]
      })

      job_story2 = job_story_fixture(%{
        title: "Mobile Performance",
        situation: "users open mobile app",
        motivation: "load quickly and not crash",
        outcome: "smooth user experience",
        product_ids: [product2.id],
        user_ids: [user2.id]
      })

      job_story3 = job_story_fixture(%{
        title: "Database Management",
        situation: "admin needs to manage data",
        motivation: "organize and backup data",
        outcome: "data integrity and security",
        product_ids: [product1.id, product2.id],
        user_ids: [user1.id, user2.id]
      })

      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      # Test 1: Initial state - should show all job stories
      html = render(index_live)
      assert html =~ job_story1.title
      assert html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 2: Apply product filter only
      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{product1.id}']")
      |> render_click()

      # Should show job stories with product1
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 3: Add search term while product filter is active
      index_live
      |> form("form[phx-change='search']", search: "checkout")
      |> render_change()

      # Should show only job story1 (matches both product filter and search)
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      refute html =~ job_story3.title

      # Test 4: Clear search while product filter remains active
      index_live
      |> element("button[phx-click='clear_search']")
      |> render_click()

      # Should show job stories with product1 (search cleared, product filter preserved)
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 5: Add user filter while product filter is active
      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{user1.id}']")
      |> render_click()

      # Should show job stories with both product1 AND user1
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 6: Add search term with both filters active
      index_live
      |> form("form[phx-change='search']", search: "database")
      |> render_change()

      # Should show only job story3 (matches product1, user1, and search)
      html = render(index_live)
      refute html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 7: Clear search with both filters active
      index_live
      |> element("button[phx-click='clear_search']")
      |> render_click()

      # Should show job stories with product1 AND user1 (search cleared, filters preserved)
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 8: Clear product filter while user filter and search are active
      index_live
      |> element("button[phx-click='clear_products_filter']")
      |> render_click()

      # Should show job stories with user1 only
      html = render(index_live)
      assert html =~ job_story1.title
      refute html =~ job_story2.title
      assert html =~ job_story3.title

      # Test 9: Clear individual filters
      index_live
      |> element("button[phx-click='clear_products_filter']")
      |> render_click()

      index_live
      |> element("button[phx-click='clear_users_filter']")
      |> render_click()

      # Should show all job stories
      html = render(index_live)
      assert html =~ job_story1.title
      assert html =~ job_story2.title
      assert html =~ job_story3.title
    end

    test "filter state is preserved when creating new job story", %{conn: conn} do
      # Create test data
      product = product_fixture(%{name: "Test Product"})
      user = user_fixture(%{pseudonym: "Test User"})

      job_story = job_story_fixture(%{
        title: "Existing Job Story",
        product_ids: [product.id],
        user_ids: [user.id]
      })

      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      # Apply filters
      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{product.id}']")
      |> render_click()

      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{user.id}']")
      |> render_click()

      # Add search term
      index_live
      |> form("form[phx-change='search']", search: "existing")
      |> render_change()

      # Verify filtered state
      html = render(index_live)
      assert html =~ job_story.title

      # Click "New Job Story" button
      index_live |> element("a", "New Job story") |> render_click()

      # Verify URL preserves filter parameters
      assert_patch(index_live, ~p"/job_stories/new?search=existing&product_ids=#{product.id}&user_ids=#{user.id}")

      # Create a new job story that matches the filters
      new_job_story_attrs = %{
        title: "New Matching Job Story",
        situation: "test situation",
        motivation: "test motivation",
        outcome: "test outcome",
        product_ids: [product.id],
        user_ids: [user.id]
      }

      index_live
      |> form("#job_story-form", job_story: new_job_story_attrs)
      |> render_submit()

      # Verify we return to the filtered view
      assert_patch(index_live, ~p"/job_stories?search=existing&product_ids=#{product.id}&user_ids=#{user.id}")

      # Verify the original job story is visible (it matches the filters)
      html = render(index_live)
      assert html =~ job_story.title

      # The new job story should not be visible because it doesn't match the search term "existing"
      # The new job story title is "New Matching Job Story" but the search is for "existing"
      refute html =~ "New Matching Job Story"
    end

    test "filter indicators are displayed correctly", %{conn: conn} do
      # Create test data
      product = product_fixture(%{name: "Test Product"})
      user = user_fixture(%{pseudonym: "Test User"})

      _job_story = job_story_fixture(%{
        title: "Unique Job Story",
        product_ids: [product.id],
        user_ids: [user.id]
      })

      {:ok, index_live, _html} = live(conn, ~p"/job_stories")

      # Test 1: No filters applied - no indicators should be visible
      html = render(index_live)
      refute html =~ "bg-indigo-100 text-indigo-800"  # Filter indicator

      # Test 2: Apply product filter - product indicator should be visible
      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{product.id}']")
      |> render_click()

      html = render(index_live)
      assert html =~ "bg-indigo-100 text-indigo-800"  # Filter indicator
      assert html =~ "1"  # Should show count of 1

      # Test 3: Apply user filter - both product and user indicators should be visible
      index_live
      |> element("div[phx-click*='toggle_filter'][phx-click*='#{user.id}']")
      |> render_click()

      html = render(index_live)
      # Should show two filter indicators (one for each filter)
      assert html =~ "bg-indigo-100 text-indigo-800"
      # Count the number of filter indicators
      filter_indicators = html |> String.split("bg-indigo-100 text-indigo-800") |> length()
      assert filter_indicators > 1  # Should have multiple filter indicators
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
