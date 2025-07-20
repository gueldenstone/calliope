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
end
