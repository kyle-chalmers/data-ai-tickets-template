# Save Work

Saves progress by adding, committing, and pushing changes with optional PR creation. If run while on the main branch, create a feature branch with an appropriate name based on work completed in this session.

**Argument**: The user types `yes` or `no` after the command. Use `/save-work yes` or `/save-work no`.

- **yes** – Stage, commit, push, AND create a pull request
- **no** – Stage, commit, and push (no PR created)

## What it does

### With "yes" (Create PR)
1. Stage all changes.
2. Create a descriptive commit with a meaningful message.
3. Push to remote with tracking.
4. Create a pull request with: business impact summary, key findings and deliverables, QC results, technical notes for reviewers.

### With "no" (Save only)
1. Stage all changes.
2. Create a descriptive commit.
3. Push to remote with tracking.

## Safety

- Never commit to main; create a feature branch first if on main.
- Use descriptive commit messages.
- Ensure PRs have proper descriptions with business context.
- Avoid empty commits.

## Requires Permission

- Push to remote
- Create PR (when using "yes")

## When to Use

**Use "no" when:** Making incremental progress, saving WIP, not ready for review yet.
**Use "yes" when:** Work is complete, documentation finished, QC passed, ready for team review.
