# Claude Code vs Cursor: AI Coding Tools for Data Analyses

> **YouTube:** [Link TBD]

Compare Claude Code and Cursor by building the same Databricks job with both tools. The real story: how context engineering and tool setup will make either tool effective.

---

## Video Goals

Viewers will learn:
1. What Cursor is, and how it differs from Claude Code
2. How Cursor's context system works (AGENTS.md + .cursorrules + Agent mode) compared to Claude Code's
3. How to build a Databricks job using either tool
4. Why you can utilize Claude Code and Cursor to complete your data analysis workflows

---

## Value Proposition

### The Problem
Data engineers and analysts are adopting AI coding tools but don't know how to configure them for maximum effectiveness. Most people install the tool and start prompting without any context engineering, getting mediocre results.

### The Solution
Context engineering - structuring your project so AI tools understand your codebase, standards, and workflow. This video shows how the same task produces quality results in BOTH tools when you invest in context files.

---

## Key Terms

- **Context Engineering** - Structuring your project so AI tools have the right information to be effective
- **AGENTS.md** - Open standard instruction file for AI coding agents (supported by 20+ tools)
- **CLAUDE.md** - Claude Code's project instruction file (Claude-specific)
- **.cursorrules** - Cursor's project rules file (Cursor-specific)
- **Custom Agents** - Claude Code feature: specialized AI agents for code review, QC, etc.
- **Custom Commands** - Claude Code feature: workflow shortcuts like /save-work, /review-work
- **Open-Meteo API** - Free weather data API (no auth required) used in the demo

---


## Comparison Framework

| Dimension | Claude Code | Cursor |
|-----------|-------------|--------|
| Context System | CLAUDE.md (700+ lines) | AGENTS.md + .cursorrules |
| Modes | Plan, bypass permissions, accept edits, etc. | Plan, debug, agent, ask |
| Models | Anthropic | Can source various models |
| Custom Agents | Yes | Yes |
| Custom Commands | Yes | Yes |
| Tool Access | CLI-native (direct terminal access) | IDE terminal (embedded) |
| Environment and UI | Terminal-based, calls features as needed and displays them as used | VS Code fork, viewable in UI with some other default features like context, web search, to-dos, and plans more easily viewable |
| Other Features | Comes with Claude app and Cowork, can be installed in Github | Only available within Cursor, can be installed in Github |
| AGENTS.md Support | Via CLAUDE.md (same content) | Built-in |
| Cost | $20 for pro$ | $20 for pro$ |
| Best For | CLI-heavy workflows, multi-tool orchestration | IDE-centric development, visual feedback |
---

But ultimately they can both do very similar things and it mostly comes down to your context engineering setup and prompting of the tool!

## Demo Task Details

**Task:** Build an automated climate data collection Databricks job

**API:** Open-Meteo Historical Weather API (free, no auth)

**Scope:** 10 Arizona cities (Phoenix, Tucson, Flagstaff, Mesa, Scottsdale, Tempe, Gilbert, Chandler, Yuma, Prescott)

**Deliverables:**
- Python script for data collection and aggregation
- Databricks job configuration (scheduled 3rd of month, 6 AM Phoenix time)
- README documentation

**Reference implementation:** `databricks_jobs_cursor/climate_data_refresh/` (from AZ Meetup Demo 2)

---

## Prerequisites

- Claude Code installed and configured
- Cursor installed with AGENTS.md/rules configured
- Databricks CLI configured (bidev profile)
- Open-Meteo API accessible (no auth needed)

---

## CLI Capabilities

### Claude Code
```bash
# Databricks operations
databricks jobs create --json @config.json
databricks jobs run-now <JOB_ID>
databricks fs cp script.py dbfs:/jobs/path/

# Git workflow
git checkout -b feature-branch
gh pr create --title "feat: description"

# Custom commands
/save-work yes    # Commit, push, create PR
/review-work .    # Run quality agents
```

### Cursor
```
# Cursor Agent mode
- Opens files, creates files, runs terminal commands
- Reads AGENTS.md and .cursorrules automatically
- IDE-integrated diff view for changes
```

---

## Resources

- [AGENTS.md Standard](https://agents.md/)
- [Claude Code Documentation](https://code.claude.com/docs/en/overview)
- [Cursor Documentation](https://cursor.com/docs)
- [Open-Meteo API](https://open-meteo.com/en/docs/historical-weather-api)
- [AZ Emerging Tech Meetup Materials](../az_emerging_tech_meetup/)
- [Existing Databricks Video](../integrating_claude_and_databricks/)

---

## Files in This Project

| File | Purpose |
|------|---------|
| `README.md` | This file - video overview and structure |
| `instructions/demo_prompt.md` | Exact prompts used in both demos |
| `instructions/cursor_setup.md` | Cursor setup guide |
| `databricks_jobs_claude` | Output from Claude Code demo (populated during recording) |
| `databricks_jobs_cursor` | Output from Cursor demo (populated during recording) |
