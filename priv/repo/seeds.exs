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

IO.puts("✅ Created #{length(products)} products")
IO.puts("✅ Created #{length(job_stories)} job stories with product associations")

# Demonstrate the many-to-many relationship
IO.puts("\n🔗 Many-to-Many Relationship Examples:")
IO.puts("=====================================")

# Get a job story with products using the context function
job_story_with_products = Storyteller.JobStories.list_job_stories() |> List.first()

if job_story_with_products do
  IO.puts("Job Story: #{job_story_with_products.title}")
  IO.puts("Associated Products:")

  Enum.each(job_story_with_products.products, fn product ->
    IO.puts("  - #{product.name}: #{product.description}")
  end)
end

# Get a product with job stories using the context function
product_with_job_stories = Storyteller.Products.list_products() |> List.first()

if product_with_job_stories do
  IO.puts("\nProduct: #{product_with_job_stories.name}")
  IO.puts("Associated Job Stories:")

  # Get job stories for this product using the context function
  job_stories_for_product =
    Storyteller.JobStories.get_job_stories_by_product(product_with_job_stories)

  if Enum.empty?(job_stories_for_product) do
    IO.puts("  - No associated job stories")
  else
    Enum.each(job_stories_for_product, fn job_story ->
      IO.puts("  - #{job_story.title}")
    end)
  end
end

IO.puts("\n🎉 Many-to-many relationship setup complete!")
IO.puts("You can now:")
IO.puts("  - Associate job stories with products")
IO.puts("  - Query job stories by product")
IO.puts("  - Query products by job story")
IO.puts("  - Use the context functions like:")
IO.puts("    - Storyteller.JobStories.list_job_stories()")
IO.puts("    - Storyteller.Products.list_products()")
