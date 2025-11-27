# Summarize Session

Shows your current position in the workflow and summarizes session progress.

## Usage

Run anytime to see where you are and what you've accomplished.

## What it shows

### 1. Current Git Status
- Current branch name
- Modified/staged files
- Commits ahead/behind main
- Warning if on main branch

### 2. Session Summary (< 100 words)
Brief summary of work completed in this session:
- Files created or modified
- Key milestones reached
- Commands executed
- Current project state

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
- "You need to create a feature branch" → Use `/initiate-request`
- "You have uncommitted changes" → Use `/save-work no-pr`
- "You're ready to submit" → Use `/save-work with-pr`
- "PR is open, waiting for review"
- "PR merged, time to clean up" → Use `/merge-work`

## Example Usage

```
You: "/summarize-session"
Claude: "━━━ GIT STATUS ━━━
        Current branch: analysis-customer-churn-q4
        Modified files: 3 (sql_queries/1_analysis.sql, README.md, qc_queries/1_check.sql)

        ━━━ SESSION SUMMARY ━━━
        Created customer churn analysis for Q4 2024. Built 3 SQL queries analyzing
        activity patterns across customer segments. Identified 2,347 churned
        customers. Created QC validation confirming 98% data accuracy.
        Documented all assumptions in README.

        (87 words)

        ━━━ WORKFLOW POSITION ━━━
        You're on a feature branch ✅
        Status: Work in progress

        ━━━ NEXT STEPS ━━━
        1. Save your current work: /save-work no-pr
        2. When ready for review: /save-work with-pr
        3. After PR merge: /merge-work"
```

## Workflow Reminders

**Golden Rules**:
- Never commit to main
- Always use feature branches
- Create PR for all changes
- Clean up after merge

**Claude Helps**:
- Prevents main branch commits
- Creates branches automatically
- Guides through each workflow step
- Summarizes your progress

---

Use this command whenever you need orientation or want to see your progress!
