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
end
