defmodule Storyteller.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Storyteller.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Storyteller.Products.create_product()

    product
  end
end
