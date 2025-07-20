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

  @doc """
  Generate a market.
  """
  def market_fixture(attrs \\ %{}) do
    {:ok, market} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Storyteller.Products.create_market()

    market
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        pseudonym: "some pseudonym",
        type: :number
      })
      |> Storyteller.Products.create_user()

    user
  end
end
