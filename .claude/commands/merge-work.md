# Merge Work

Completes your workflow by merging the PR, cleaning up branches, and returning to main.

## Usage

Run this command after your PR has been approved and is ready to merge.

## What it does

### 1. Merges the Pull Request
- Identifies the PR for your current branch
- Merges the PR using merge commit strategy
- Confirms successful merge

### 2. Deletes Local Branch
- Switches to main branch first
- Deletes the feature branch locally
- Cleans up your local environment

### 3. Updates Main Branch
- Pulls latest changes from origin/main
- Ensures you're up to date with the merged code
- Ready to start next project

### 4. Cleanup Confirmation
- Shows summary of what was cleaned up
- Confirms you're back on main
- Displays clean slate status

## Example Usage

```
You: "/merge-work"
Claude: "Let me merge your PR and clean up..."

        ✅ Merged PR #123: "Add fraud pattern analysis"
        ✅ Deleted local branch: DS-456-fraud-pattern-analysis
        ✅ Switched to main
        ✅ Pulled latest changes

        "Clean slate! Ready to start your next project."
```

## Prerequisites

- You have a pull request created
- The PR has been approved (or you're ready to merge it)
- You're currently on the feature branch to be merged

## Requires Permission

- Merging pull request
- Deleting local branch (safe operation)

## Safety Features

- Confirms PR exists before attempting merge
- Verifies you want to merge before proceeding
- Saves you from merge conflicts by pulling latest main
- Prevents accidental branch deletion

---

This command completes your work cycle cleanly!
