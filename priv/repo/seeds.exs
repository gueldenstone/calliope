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

# Clear existing job stories
Repo.delete_all(JobStory)

# Create sample job stories
job_stories = [
  %{
    title: "E-commerce Checkout Optimization",
    situation: "users reach the checkout page",
    motivation: "complete their purchase quickly and securely",
    outcome: "they don't abandon their cart and we increase our conversion rates"
  },
  %{
    title: "Mobile App Performance",
    situation: "users open our mobile app",
    motivation: "load quickly and not crash",
    outcome: "they have a smooth experience and continue using our app"
  },
  %{
    title: "Customer Support Response",
    situation: "customers submit support tickets",
    motivation: "respond to them quickly with helpful information",
    outcome: "they feel supported and remain satisfied with our service"
  },
  %{
    title: "Database Migration",
    situation: "we need to upgrade our database",
    motivation: "migrate the data safely without losing any information",
    outcome: "our service remains available and all user data is preserved"
  },
  %{
    title: "API Rate Limiting",
    situation: "users make requests to our API",
    motivation: "limit excessive usage to prevent abuse",
    outcome: "all users get fair access and our service remains stable"
  },
  %{
    title: "Security Vulnerability Fix",
    situation: "a security vulnerability is discovered",
    motivation: "patch it immediately",
    outcome: "our users' data remains protected and secure"
  },
  %{
    title: "Payment System Backup",
    situation: "our primary payment processor goes down",
    motivation: "automatically switch to a backup system",
    outcome: "customers can still complete their purchases without interruption"
  },
  %{
    title: "User Onboarding",
    situation: "new users sign up for our service",
    motivation: "guide them through a simple onboarding process",
    outcome: "they understand how to use our product and become active users"
  }
]

# Insert all job stories
Enum.each(job_stories, fn job_story_attrs ->
  %JobStory{}
  |> JobStory.changeset(job_story_attrs)
  |> Repo.insert!()
end)

IO.puts("✅ Created #{length(job_stories)} job stories")
