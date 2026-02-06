# Merge Work

Completes the workflow by merging the PR, cleaning up branches, and returning to main.

Run after the PR has been approved and is ready to merge.

## What it does

1. **Merges the Pull Request** – Identify the PR for the current branch, merge (merge commit strategy), confirm success.
2. **Deletes Local Branch** – Switch to main, delete the feature branch locally.
3. **Updates Main** – Pull latest from origin/main.
4. **Cleanup Confirmation** – Summarize what was cleaned up, confirm back on main.

## Prerequisites

- A pull request exists for the current branch.
- The PR is approved (or ready to merge).
- You are on the feature branch to be merged.

## Requires Permission

- Merging the pull request
- Deleting the local branch

## Safety

- Confirm PR exists before attempting merge.
- Verify you want to merge before proceeding.
- Pull latest main to avoid merge conflicts.
- Prevents accidental branch deletion.
