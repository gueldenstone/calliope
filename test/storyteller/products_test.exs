defmodule Storyteller.ProductsTest do
  use Storyteller.DataCase

  alias Storyteller.Products

  describe "products" do
    alias Storyteller.Products.Product

    import Storyteller.ProductsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.description == "some description"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.description == "some updated description"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end

  describe "markets" do
    alias Storyteller.Products.Market

    import Storyteller.ProductsFixtures

    @invalid_attrs %{name: nil}

    test "list_markets/0 returns all markets" do
      market = market_fixture()
      assert Products.list_markets() == [market]
    end

    test "get_market!/1 returns the market with given id" do
      market = market_fixture()
      assert Products.get_market!(market.id) == market
    end

    test "create_market/1 with valid data creates a market" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Market{} = market} = Products.create_market(valid_attrs)
      assert market.name == "some name"
    end

    test "create_market/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_market(@invalid_attrs)
    end

    test "update_market/2 with valid data updates the market" do
      market = market_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Market{} = market} = Products.update_market(market, update_attrs)
      assert market.name == "some updated name"
    end

    test "update_market/2 with invalid data returns error changeset" do
      market = market_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_market(market, @invalid_attrs)
      assert market == Products.get_market!(market.id)
    end

    test "delete_market/1 deletes the market" do
      market = market_fixture()
      assert {:ok, %Market{}} = Products.delete_market(market)
      assert_raise Ecto.NoResultsError, fn -> Products.get_market!(market.id) end
    end

    test "change_market/1 returns a market changeset" do
      market = market_fixture()
      assert %Ecto.Changeset{} = Products.change_market(market)
    end
  end

  describe "users" do
    alias Storyteller.Products.User

    import Storyteller.ProductsFixtures

    @invalid_attrs %{type: nil, pseudonym: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Products.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Products.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{type: :number, pseudonym: "some pseudonym"}

      assert {:ok, %User{} = user} = Products.create_user(valid_attrs)
      assert user.type == :number
      assert user.pseudonym == "some pseudonym"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{type: :salesforce, pseudonym: "some updated pseudonym"}

      assert {:ok, %User{} = user} = Products.update_user(user, update_attrs)
      assert user.type == :salesforce
      assert user.pseudonym == "some updated pseudonym"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_user(user, @invalid_attrs)
      assert user == Products.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Products.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Products.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Products.change_user(user)
    end
  end
end
