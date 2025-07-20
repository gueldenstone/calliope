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
    situation:
      "Our e-commerce platform was experiencing a 35% cart abandonment rate during the checkout process. Users were dropping off at the payment information step, and our conversion rates were below industry standards.",
    motivation:
      "We needed to reduce cart abandonment and increase conversion rates to meet our quarterly revenue targets. The checkout process was identified as the primary bottleneck affecting our business metrics.",
    outcome:
      "Implemented a streamlined checkout flow with saved payment methods, guest checkout option, and progress indicators. Cart abandonment decreased to 18% and conversion rates improved by 42% within 3 months."
  },
  %{
    title: "Mobile App Performance Crisis",
    situation:
      "Our mobile app was crashing for 15% of users on iOS devices, particularly on older iPhone models. User complaints were increasing daily, and our App Store rating dropped from 4.2 to 3.1 stars.",
    motivation:
      "We needed to stabilize the app immediately to prevent further user loss and maintain our App Store presence. The crashes were affecting our core user base and damaging our brand reputation.",
    outcome:
      "Identified memory leaks in image caching and optimized database queries. Reduced crash rate to 2% and restored App Store rating to 4.3 stars within 6 weeks."
  },
  %{
    title: "Customer Support Ticket Backlog",
    situation:
      "Our customer support team was overwhelmed with 2,500+ open tickets, with average response times of 72 hours. Customer satisfaction scores had dropped to 65%, and our support team was experiencing high turnover.",
    motivation:
      "We needed to reduce ticket volume and improve response times to restore customer satisfaction and prevent team burnout. The backlog was affecting our ability to retain customers and grow the business.",
    outcome:
      "Implemented an AI-powered FAQ system and automated ticket categorization. Reduced open tickets by 60% and improved average response time to 8 hours. Customer satisfaction increased to 88%."
  },
  %{
    title: "Database Migration Failure",
    situation:
      "During a planned database migration from PostgreSQL 11 to 14, the process failed at 60% completion, leaving our production system in an inconsistent state. Users were experiencing data loss and service interruptions.",
    motivation:
      "We needed to restore service immediately and complete the migration safely to prevent data corruption and minimize downtime. The partial migration had created data integrity issues that needed urgent resolution.",
    outcome:
      "Executed a rollback plan within 2 hours, then successfully completed the migration during off-peak hours with improved monitoring. Achieved zero data loss and completed migration with only 4 hours of planned downtime."
  },
  %{
    title: "API Rate Limiting Implementation",
    situation:
      "Our public API was being abused by a few users making 10,000+ requests per minute, causing performance degradation for all users and increasing our infrastructure costs by 300%.",
    motivation:
      "We needed to implement rate limiting to protect our service from abuse while ensuring legitimate users weren't affected. The abuse was threatening our service reliability and profitability.",
    outcome:
      "Implemented tiered rate limiting with API keys and user-based quotas. Reduced abusive traffic by 95% while maintaining 99.9% uptime for legitimate users. Infrastructure costs returned to normal levels."
  },
  %{
    title: "Security Vulnerability Discovery",
    situation:
      "A security researcher reported a critical SQL injection vulnerability in our user authentication system that could potentially expose all user data, including passwords and personal information.",
    motivation:
      "We needed to patch the vulnerability immediately to protect our users' data and maintain trust. The vulnerability posed a significant security and compliance risk to our platform.",
    outcome:
      "Deployed a hotfix within 4 hours, implemented input validation and parameterized queries, and conducted a security audit. No user data was compromised, and we received positive recognition from the security community."
  },
  %{
    title: "Third-Party Integration Failure",
    situation:
      "Our payment processor's API experienced a 6-hour outage, preventing all new transactions on our platform. We had no fallback payment method, and customers were unable to complete purchases.",
    motivation:
      "We needed to implement a backup payment solution to ensure business continuity and prevent revenue loss during third-party outages. The dependency on a single payment provider was a critical business risk.",
    outcome:
      "Implemented a secondary payment processor and automatic failover system within 48 hours. During the next outage, we maintained 100% transaction processing capability and prevented any revenue loss."
  },
  %{
    title: "User Onboarding Drop-off",
    situation:
      "Our new user onboarding flow had a 70% drop-off rate, with most users abandoning the process at the email verification step. This was limiting our user acquisition and growth potential.",
    motivation:
      "We needed to simplify the onboarding process to increase user activation rates and reduce the cost of customer acquisition. The complex onboarding was preventing us from scaling our user base effectively.",
    outcome:
      "Redesigned the onboarding flow with social login options and progressive disclosure. Reduced drop-off rate to 25% and increased monthly active users by 150% within 2 months."
  }
]

# Insert all job stories
Enum.each(job_stories, fn job_story_attrs ->
  %JobStory{}
  |> JobStory.changeset(job_story_attrs)
  |> Repo.insert!()
end)

IO.puts("✅ Created #{length(job_stories)} job stories")
