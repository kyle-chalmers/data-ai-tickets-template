# Save Work

Saves your progress by adding, committing, and pushing changes with optional PR creation.

## Usage

```
/save-work yes    # Save and create PR
/save-work no     # Save without PR
```

## Arguments

**yes** - Adds, commits, pushes, AND creates a pull request
**no** - Adds, commits, and pushes (no PR created)

## What it does

### With "yes" argument (Create PR)
1. **Stages all changes** - Adds all modified and new files
2. **Creates descriptive commit** - Generates meaningful commit message
3. **Pushes to remote** - Uploads to origin with tracking
4. **Creates pull request** - Generates comprehensive PR with:
   - Business impact summary
   - Key findings and deliverables
   - QC results
   - Technical notes for reviewers

### With "no" argument (Save only)
1. **Stages all changes** - Adds all modified and new files
2. **Creates descriptive commit** - Generates meaningful commit message
3. **Pushes to remote** - Uploads to origin with tracking

## Example Usage

### Save and Create PR
```
You: "/save-work yes"
Claude: "Let me save your work and create a PR..."

        ✅ Staged all changes (5 files)
        ✅ Committed: "Add fraud pattern analysis with QC validation"
        ✅ Pushed to origin/DS-456-fraud-pattern-analysis
        ✅ Created PR #123: "Add fraud pattern analysis"
           → https://github.com/.../pull/123

        "Your work is saved and ready for review!"
```

### Save Without PR
```
You: "/save-work no"
Claude: "Saving your work..."

        ✅ Staged all changes (3 files)
        ✅ Committed: "Update exploratory analysis queries"
        ✅ Pushed to origin/pricing-model-update

        "Work saved! Continue when ready."
```

## Safety Features

**Prevents**:
- Commits to main branch
- Pushes to main accidentally
- PRs without proper description
- Empty commits

**Ensures**:
- Always on feature branch before operating
- Descriptive commit messages
- Proper PR formatting with business context
- Clean git history

## Requires Permission

- Push to remote
- Create PR (when using "yes")

## When to Use Which Argument

**Use "no" when:**
- Making incremental progress
- Saving work in progress
- Not ready for review yet
- Want to keep working

**Use "yes" when:**
- Work is complete
- Documentation is finished
- QC checks passed
- Ready for team review

---

This is your primary command for saving progress and submitting work!
