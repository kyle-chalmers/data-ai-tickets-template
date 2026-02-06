# Summarize Session

Shows current workflow position and session progress.

Run anytime to see where you are and what you've accomplished.

## What it shows

### 1. Current Git Status
- Current branch name
- Modified/staged files
- Commits ahead/behind main
- Warning if on main branch

### 2. Session Summary (< 100 words)
Brief summary of work completed: files created/modified, key milestones, commands executed, current project state.

### 3. Workflow Position
```
main (protected)
  ↓
  Create feature branch
  ↓
  Work (commits, pushes)  ← You are here
  ↓
  Create PR
  ↓
  Review → Merge
  ↓
  Cleanup → Back to main
```

### 4. Next Steps
Personalized guidance based on current state:
- Need feature branch → Use `/initiate-request`
- Uncommitted changes → Use `/save-work no`
- Ready to submit → Use `/save-work yes`
- PR open, waiting for review
- PR merged, time to clean up → Use `/merge-work`

## Workflow Reminders

- Never commit to main.
- Always use feature branches.
- Create PR for all changes.
- Clean up after merge.
