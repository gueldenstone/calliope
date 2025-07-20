defmodule Storyteller.Seeds do
  alias Storyteller.Repo
  alias Storyteller.JobStories.JobStory
  alias Storyteller.Products.Product
  alias Storyteller.Products.Market

  def run do
    # Clear existing data
    Repo.delete_all(JobStory)
    Repo.delete_all(Product)

    # Create sample products
    products = [
      %{
        name: "Product A",
        description: "A comprehensive e-commerce solution for online stores"
      },
      %{
        name: "Product B",
        description: "A comprehensive e-commerce solution for online stores"
      }
    ]

    # Insert all products
    _inserted_products =
      Enum.map(products, fn product_attrs ->
        %Product{}
        |> Product.changeset(product_attrs)
        |> Repo.insert!()
      end)

    # Create sample job stories with varying similarity patterns for testing
    job_stories = [
      # Group 1: Sound System Stories (similar situations, varying motivations/outcomes)
      %{
        title: "Sound System Setup - Quick Control",
        situation: "I'm setting up a sound system",
        motivation: "have full control over the parameters with as few clicks as possible",
        outcome: "I can set up the sound system quickly and easily"
      },
      %{
        title: "Sound System Setup - Visual Layout",
        situation: "I'm setting up a sound system",
        motivation: "see the sound system as it is laid out in physical space",
        outcome: "I can find the entities I'd like to control easily"
      },
      %{
        title: "Sound System Planning",
        situation: "I'm planning a sound system",
        motivation: "have a clear understanding of the physical properties of the venue",
        outcome: "I can plan the sound system precisely"
      },

      # Group 2: User Authentication Stories (similar motivations, varying situations/outcomes)
      %{
        title: "User Login Implementation",
        situation: "users need to access the application",
        motivation: "implement secure authentication",
        outcome: "users can safely log into their accounts"
      },
      %{
        title: "API Authentication Setup",
        situation: "external services need to access our API",
        motivation: "implement secure authentication",
        outcome: "only authorized services can access our endpoints"
      },
      %{
        title: "Admin Panel Security",
        situation: "administrators need to manage the system",
        motivation: "implement secure authentication",
        outcome: "only authorized admins can access sensitive functions"
      },

      # Group 3: Database Stories (similar outcomes, varying situations/motivations)
      %{
        title: "Database Migration Tool",
        situation: "we need to upgrade our database schema",
        motivation: "safely migrate data without downtime",
        outcome: "database is upgraded with all data preserved"
      },
      %{
        title: "Backup System Implementation",
        situation: "we need to protect our data from loss",
        motivation: "create automated backup processes",
        outcome: "database is upgraded with all data preserved"
      },
      %{
        title: "Data Recovery Process",
        situation: "we need to restore data after a failure",
        motivation: "implement reliable recovery procedures",
        outcome: "database is upgraded with all data preserved"
      },

      # Group 4: Performance Optimization Stories (similar motivations, different domains)
      %{
        title: "Website Performance Optimization",
        situation: "users are experiencing slow page loads",
        motivation: "improve system performance",
        outcome: "pages load quickly and users have a better experience"
      },
      %{
        title: "Database Query Optimization",
        situation: "reports are taking too long to generate",
        motivation: "improve system performance",
        outcome: "reports generate quickly and efficiently"
      },
      %{
        title: "Mobile App Performance",
        situation: "app is consuming too much battery",
        motivation: "improve system performance",
        outcome: "app runs efficiently with minimal battery usage"
      },

      # Group 5: User Experience Stories (similar outcomes, different contexts)
      %{
        title: "Shopping Cart Checkout",
        situation: "customers are abandoning their carts",
        motivation: "streamline the purchase process",
        outcome: "customers complete their purchases smoothly"
      },
      %{
        title: "User Onboarding Flow",
        situation: "new users are confused about getting started",
        motivation: "create a clear introduction process",
        outcome: "customers complete their purchases smoothly"
      },
      %{
        title: "Support Ticket Resolution",
        situation: "customers are waiting too long for help",
        motivation: "expedite the support process",
        outcome: "customers complete their purchases smoothly"
      },

      # Group 6: Security Stories (similar situations, different motivations)
      %{
        title: "Firewall Configuration",
        situation: "our system is vulnerable to attacks",
        motivation: "block unauthorized access attempts",
        outcome: "system is protected from external threats"
      },
      %{
        title: "Intrusion Detection Setup",
        situation: "our system is vulnerable to attacks",
        motivation: "monitor for suspicious activity",
        outcome: "we can detect and respond to security incidents"
      },
      %{
        title: "Security Audit Implementation",
        situation: "our system is vulnerable to attacks",
        motivation: "identify existing security gaps",
        outcome: "we have a clear picture of our security posture"
      },

      # Group 7: Monitoring Stories (similar motivations, different contexts)
      %{
        title: "Server Monitoring Setup",
        situation: "we need to track system health",
        motivation: "detect issues before they become problems",
        outcome: "we can proactively address system issues"
      },
      %{
        title: "Application Error Tracking",
        situation: "we need to track system health",
        motivation: "detect issues before they become problems",
        outcome: "we can identify and fix bugs quickly"
      },
      %{
        title: "User Behavior Analytics",
        situation: "we need to track system health",
        motivation: "detect issues before they become problems",
        outcome: "we can optimize user experience based on data"
      },

      # Group 8: Integration Stories (similar outcomes, different domains)
      %{
        title: "Payment Gateway Integration",
        situation: "we need to accept online payments",
        motivation: "connect with external payment services",
        outcome: "customers can pay securely through our platform"
      },
      %{
        title: "Email Service Integration",
        situation: "we need to send automated emails",
        motivation: "connect with external email services",
        outcome: "customers can pay securely through our platform"
      },
      %{
        title: "Social Media Integration",
        situation: "we need to share content on social platforms",
        motivation: "connect with external social media APIs",
        outcome: "customers can pay securely through our platform"
      }
    ]

    # Insert all job stories with their associated products
    Enum.each(job_stories, fn job_story_attrs ->
      Storyteller.JobStories.create_job_story(job_story_attrs)
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
  end
end
