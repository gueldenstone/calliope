# Centralized Association Management

This document describes the centralized association pattern used in the Storyteller application to prevent issues with missing preloads and ensure consistent association management.

## Overview

The centralized association pattern provides:
- **Single source of truth** for association definitions
- **Automatic preloading** of all associations when needed
- **Safe association updates** that preserve existing associations
- **Consistent API** across all contexts

## Implementation

### 1. Centralized Association Definitions

Each context defines its associations at the module level:

```elixir
# In lib/storyteller/job_stories.ex
@job_story_associations [:products, :users]

# In lib/storyteller/products.ex
@product_associations [:job_stories]
@market_associations [:users]
@user_associations [:markets, :job_stories]
```

### 2. Helper Functions

Each context provides helper functions to access associations:

```elixir
def job_story_associations, do: @job_story_associations
def product_associations, do: @product_associations
def market_associations, do: @market_associations
def user_associations, do: @user_associations
```

### 3. Consistent Preloading

All queries use the centralized associations:

```elixir
def list_job_stories do
  JobStory
  |> preload(^@job_story_associations)
  |> Repo.all()
end
```

### 4. Safe Association Updates

Generic helper functions ensure associations are preserved:

```elixir
def update_job_story_association(%JobStory{} = job_story, association, new_value) do
  # Get the current job story with all associations preloaded
  job_story_with_associations = Repo.preload(job_story, @job_story_associations)

  # Create a changeset that preserves all existing associations
  changeset = JobStory.changeset(job_story_with_associations, %{})
  
  # Update the specific association
  changeset = Ecto.Changeset.put_assoc(changeset, association, new_value)
  
  # Explicitly preserve all other associations
  changeset = Enum.reduce(@job_story_associations, changeset, fn assoc, acc_changeset ->
    if assoc != association do
      existing_value = Map.get(job_story_with_associations, assoc)
      Ecto.Changeset.put_assoc(acc_changeset, assoc, existing_value)
    else
      acc_changeset
    end
  end)

  Repo.update(changeset)
end
```

## Usage Examples

### Updating Job Story Associations

```elixir
# Update products while preserving users
JobStories.associate_products_with_job_story(job_story, [product1, product2])

# Update users while preserving products
JobStories.associate_users_with_job_story(job_story, [user1, user2])

# Generic update (internal use)
JobStories.update_job_story_association(job_story, :products, [product1, product2])
```

### Updating User Associations

```elixir
# Update markets while preserving job stories
Products.associate_markets_with_user(user, [market1, market2])

# Update job stories while preserving markets
Products.associate_job_stories_with_user(user, [job_story1, job_story2])
```

## Benefits

1. **Prevents Missing Preloads**: All associations are automatically preloaded when needed
2. **Preserves Data Integrity**: Updates to one association don't affect others
3. **Consistent API**: All contexts follow the same pattern
4. **Easy Maintenance**: Adding new associations only requires updating the module-level definition
5. **Type Safety**: Compile-time checking of association names

## Adding New Associations

To add a new association:

1. **Update the module-level definition**:
   ```elixir
   @job_story_associations [:products, :users, :new_association]
   ```

2. **Add a helper function** (optional):
   ```elixir
   def associate_new_association_with_job_story(%JobStory{} = job_story, items) do
     update_job_story_association(job_story, :new_association, items)
   end
   ```

3. **Update the schema** to include the association

4. **Run tests** to ensure everything works correctly

## Migration Guide

When migrating existing code to use this pattern:

1. Replace hardcoded preloads with centralized ones
2. Replace direct `put_assoc` calls with the helper functions
3. Update tests to use the new API
4. Verify that all associations are preserved during updates

## Testing

The pattern includes comprehensive tests to ensure:
- Associations are properly preloaded
- Updates preserve existing associations
- Combined filters work correctly
- No data is lost during association updates 
