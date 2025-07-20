# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Storyteller.Repo.insert!(%Storyteller.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

## Job Stories

alias Storyteller.Repo
alias Storyteller.JobStories.JobStory
alias Storyteller.Products.Product
alias Storyteller.Products.Market

# Clear existing data
Repo.delete_all(JobStory)
Repo.delete_all(Product)

# Create sample products
products = [
  %{
    name: "E-commerce Platform",
    description: "A comprehensive e-commerce solution for online stores"
  },
  %{
    name: "Mobile App",
    description: "Cross-platform mobile application for iOS and Android"
  },
  %{
    name: "Customer Support System",
    description: "Ticketing and support management platform"
  },
  %{
    name: "Database Management",
    description: "Database administration and migration tools"
  },
  %{
    name: "API Gateway",
    description: "API management and rate limiting service"
  },
  %{
    name: "Security Suite",
    description: "Comprehensive security and vulnerability management"
  },
  %{
    name: "Payment Processing",
    description: "Multi-provider payment processing system"
  },
  %{
    name: "User Management",
    description: "User authentication and onboarding platform"
  }
]

# Insert all products
inserted_products =
  Enum.map(products, fn product_attrs ->
    %Product{}
    |> Product.changeset(product_attrs)
    |> Repo.insert!()
  end)

# Create sample job stories
job_stories = [
  %{
    title: "E-commerce Checkout Optimization",
    situation: "users reach the checkout page",
    motivation: "complete their purchase quickly and securely",
    outcome: "they don't abandon their cart and we increase our conversion rates",
    # E-commerce Platform, Payment Processing
    product_ids: [Enum.at(inserted_products, 0).id, Enum.at(inserted_products, 6).id]
  },
  %{
    title: "Mobile App Performance",
    situation: "users open our mobile app",
    motivation: "load quickly and not crash",
    outcome: "they have a smooth experience and continue using our app",
    # Mobile App
    product_ids: [Enum.at(inserted_products, 1).id]
  },
  %{
    title: "Customer Support Response",
    situation: "customers submit support tickets",
    motivation: "respond to them quickly with helpful information",
    outcome: "they feel supported and remain satisfied with our service",
    # Customer Support System
    product_ids: [Enum.at(inserted_products, 2).id]
  },
  %{
    title: "Database Migration",
    situation: "we need to upgrade our database",
    motivation: "migrate the data safely without losing any information",
    outcome: "our service remains available and all user data is preserved",
    # Database Management
    product_ids: [Enum.at(inserted_products, 3).id]
  },
  %{
    title: "API Rate Limiting",
    situation: "users make requests to our API",
    motivation: "limit excessive usage to prevent abuse",
    outcome: "all users get fair access and our service remains stable",
    # API Gateway
    product_ids: [Enum.at(inserted_products, 4).id]
  },
  %{
    title: "Security Vulnerability Fix",
    situation: "a security vulnerability is discovered",
    motivation: "patch it immediately",
    outcome: "our users' data remains protected and secure",
    # Security Suite
    product_ids: [Enum.at(inserted_products, 5).id]
  },
  %{
    title: "Payment System Backup",
    situation: "our primary payment processor goes down",
    motivation: "automatically switch to a backup system",
    outcome: "customers can still complete their purchases without interruption",
    # E-commerce Platform, Payment Processing
    product_ids: [Enum.at(inserted_products, 0).id, Enum.at(inserted_products, 6).id]
  },
  %{
    title: "User Onboarding",
    situation: "new users sign up for our service",
    motivation: "guide them through a simple onboarding process",
    outcome: "they understand how to use our product and become active users",
    # User Management
    product_ids: [Enum.at(inserted_products, 7).id]
  }
]

# Insert all job stories with their associated products
Enum.each(job_stories, fn job_story_attrs ->
  %JobStory{}
  |> JobStory.changeset(job_story_attrs)
  |> Repo.insert!()
end)

markets = [
  %{
    name: "Market 1"
  },
  %{
    name: "Market 2"
  }
]

Enum.each(markets, fn market_attrs ->
  %Market{}
  |> Market.changeset(market_attrs)
  |> Repo.insert!()
end)
