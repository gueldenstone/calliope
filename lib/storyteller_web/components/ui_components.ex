defmodule StorytellerWeb.UIComponents do
  @moduledoc """
  Provides reusable UI components specific to the Storyteller application.
  """
  use Phoenix.Component

  import StorytellerWeb.CoreComponents

  @doc """
  Renders a navigation button with customizable destination, text, icon, and styling.

  ## Examples

      <.nav_button navigate={~p"/job_stories"} text="View Job Stories" icon="hero-document-text" />

      <.nav_button
        navigate={~p"/job_stories/new"}
        text="Create New Story"
        icon="hero-plus"
        class="bg-green-600 hover:bg-green-700"
      />

      <.nav_button
        navigate={~p"/settings"}
        text="Settings"
        icon="hero-cog-6-tooth"
        class="bg-gray-600 hover:bg-gray-700"
      />
  """
  attr :navigate, :string, required: true, doc: "navigation path"
  attr :text, :string, required: true, doc: "button text"
  attr :icon, :string, default: nil, doc: "heroicon name (optional)"

  attr :class, :string,
    default: "bg-indigo-600 hover:bg-indigo-700",
    doc: "additional CSS classes"

  attr :rest, :global, doc: "additional HTML attributes"

  def nav_button(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "inline-flex items-center px-8 py-4 text-white font-semibold rounded-lg shadow-lg",
        "transition-colors duration-200 transform hover:scale-105",
        @class
      ]}
      {@rest}
    >
      <%= if @icon do %>
        <.icon name={@icon} class="w-5 h-5 mr-2" />
      <% end %>
      {@text}
    </.link>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(patch href navigate)
  slot :inner_block, required: true

  def a(assigns) do
    ~H"""
    <.link class={["hover:opacity-50 transition-opacity", @class]} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a list of associated items as badges with customizable styling.

  ## Examples

      <.associated_items items={user.markets} name_field="name" empty_text="No markets" />

      <.associated_items
        items={job_story.products}
        name_field="name"
        empty_text="No products"
        badge_class="bg-green-100 text-green-800"
      />

      <.associated_items
        items={user.roles}
        name_field="title"
        empty_text="No roles assigned"
        badge_class="bg-purple-100 text-purple-800"
      />
  """
  attr :items, :list, required: true, doc: "list of items to display"
  attr :name_field, :atom, required: true, doc: "field name to display for each item"
  attr :empty_text, :string, default: "No items", doc: "text to show when list is empty"

  attr :badge_class, :string,
    default: "bg-blue-100 text-blue-800",
    doc: "CSS classes for badge styling"

  attr :empty_class, :string, default: "text-gray-400", doc: "CSS classes for empty state text"

  def associated_items(assigns) do
    ~H"""
    <%= if Enum.empty?(@items) do %>
      <span class={@empty_class}>{@empty_text}</span>
    <% else %>
      <div class="flex flex-wrap gap-1">
        <%= for item <- @items do %>
          <span class={[
            "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium",
            @badge_class
          ]}>
            {Map.get(item, @name_field)}
          </span>
        <% end %>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders a table with filterable column headers.

  ## Examples

      <.filterable_table
        id="job_stories"
        rows={@streams.job_stories}
        filters={[
          %{key: :products, items: @products, name_field: :name, selected_ids: @selected_product_ids},
          %{key: :users, items: @users, name_field: :pseudonym, selected_ids: @selected_user_ids}
        ]}
        phx_change="filter_change"
      >
        <:col :let={{_id, job_story}} label="Title">{job_story.title}</:col>
        <:col :let={{_id, job_story}} label="Products" filterable="products">
          <.associated_items items={job_story.products} name_field={:name} empty_text="No products" />
        </:col>
        <:col :let={{_id, job_story}} label="Users" filterable="users">
          <.associated_items items={job_story.users} name_field={:pseudonym} empty_text="No users" />
        </:col>
      </.filterable_table>

  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :filters, :list, required: true, doc: "List of filter configurations"
  attr :phx_change, :string, required: true, doc: "Event to trigger on filter change"
  attr :row_click, :any, default: nil
  attr :rest, :global, include: ~w(class)

  slot :col, required: true do
    attr :label, :string, required: true
    attr :filterable, :string, doc: "Filter key for this column"
    attr :search_active, :boolean, doc: "Whether search is active for this column"
  end

  slot :action, doc: "Action buttons for each row"

  def filterable_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200" id={@id} {@rest}>
        <thead class="bg-gray-50">
          <tr>
            <%= for col <- @col do %>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <div class="relative">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                      <span>{col.label}</span>
                      <%= if Map.get(col, :filterable) do %>
                        <% filter_config = Enum.find(@filters, &(&1.key == String.to_atom(col.filterable))) %>
                        <%= if filter_config && length(filter_config.selected_ids) > 0 do %>
                          <span class="inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                            {length(filter_config.selected_ids)}
                          </span>
                        <% end %>
                      <% end %>
                    </div>
                    <%= if Map.get(col, :filterable) do %>
                      <button
                        type="button"
                        class={[
                          "ml-2 hover:text-gray-600",
                          if(Enum.find(@filters, &(&1.key == String.to_atom(col.filterable))) |> then(fn config -> config && length(config.selected_ids) > 0 end)) do
                            "text-indigo-600"
                          else
                            "text-gray-400"
                          end
                        ]}
                        phx-click={
                          Phoenix.LiveView.JS.toggle(to: "#filter-dropdown-#{col.filterable}")
                        }
                        aria-label="Filter by #{col.label}"
                      >
                        <.icon name="hero-funnel" class="w-4 h-4" />
                      </button>
                    <% end %>
                  </div>

                  <%= if Map.get(col, :filterable) do %>
                    {render_filter_dropdown(col, @filters)}
                  <% end %>
                </div>
              </th>
            <% end %>
            <%= if @action do %>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <%= for {id, row} <- @rows do %>
            <tr
              id={id}
              class="hover:bg-gray-50 cursor-pointer"
              phx-click={@row_click && @row_click.({id, row})}
            >
              <%= for col <- @col do %>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {render_slot(col, {id, row})}
                </td>
              <% end %>
              <%= if @action do %>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= for action <- @action do %>
                    {render_slot(action, {id, row})}
                  <% end %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp render_filter_dropdown(col, filters) do
    filter_config = Enum.find(filters, &(&1.key == String.to_atom(col.filterable)))

    if filter_config do
      assigns = %{col: col, filter_config: filter_config}

      ~H"""
      <div
        id={"filter-dropdown-#{@col.filterable}"}
        class="hidden fixed z-50 mt-2 w-64 bg-white rounded-md shadow-lg border border-gray-200"
        phx-click-away={Phoenix.LiveView.JS.hide(to: "#filter-dropdown-#{@col.filterable}")}
      >
        <div class="p-4">
          <h3 class="text-sm font-medium text-gray-900 mb-3">Filter by {@col.label}</h3>
          <div class="space-y-2 min-h-32 max-h-48 overflow-y-auto">
            <%= for item <- @filter_config.items do %>
              <div
                class="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 p-1 rounded"
                phx-click={
                  Phoenix.LiveView.JS.push("toggle_filter",
                    value: %{
                      "filter_type" => @col.filterable,
                      "item_id" => item.id
                    }
                  )
                }
              >
                <div class={[
                  "w-4 h-4 rounded border-2 flex items-center justify-center",
                  if(item.id in @filter_config.selected_ids) do
                    "border-indigo-600 bg-indigo-600"
                  else
                    "border-gray-300 bg-white"
                  end
                ]}>
                  <%= if item.id in @filter_config.selected_ids do %>
                    <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% end %>
                </div>
                <span class="text-sm text-gray-700">
                  {Map.get(item, @filter_config.name_field)}
                </span>
              </div>
            <% end %>
          </div>
          <div class="mt-3 pt-3 border-t border-gray-200">
            <button
              type="button"
              class="text-sm text-indigo-600 hover:text-indigo-500"
              phx-click={"clear_#{@col.filterable}_filter"}
            >
              Clear filter
            </button>
          </div>
        </div>
      </div>
      """
    end
  end
end
