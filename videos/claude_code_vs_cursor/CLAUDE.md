# Claude Code vs Cursor Video - Technical Reference

Quick reference for this video project comparing Claude Code and Cursor.

---

## Project Context

**Video Concept:** Build the same Databricks job with Claude Code and Cursor, then compare the experience. Key topic: AGENTS.md as a universal context engineering standard.

**Origin:** Demo 2 from AZ Emerging Tech Meetup (January 21, 2026) - originally built a Databricks job for Arizona weather data collection. This video redoes that task with both tools.

**Reference Implementation:** `/databricks_jobs_cursor/climate_data_refresh/` contains the original meetup output.

---

## Demo Task Specification

### What We're Building
Automated monthly weather data collection for 10 Arizona cities using the Open-Meteo API, stored as a Databricks scheduled job.

### API Details
- **API:** Open-Meteo Historical Weather API
- **Base URL:** `https://archive-api.open-meteo.com/v1/archive`
- **Auth:** None required (free)
- **Rate Limit:** 10,000 requests/day
- **Data Lag:** ~5 days
- **Variables:** temperature_2m_max, temperature_2m_min, temperature_2m_mean, precipitation_sum, wind_speed_10m_max, relative_humidity_2m_mean

### Cities
Phoenix (33.45, -112.07), Tucson (32.22, -110.93), Flagstaff (35.20, -111.65), Mesa (33.42, -111.83), Scottsdale (33.49, -111.93), Tempe (33.43, -111.94), Gilbert (33.35, -111.79), Chandler (33.30, -111.84), Yuma (32.69, -114.62), Prescott (34.54, -112.47)

### Job Schedule
- **Cron:** `0 0 6 3 * ?` (6 AM on 3rd of month)
- **Timezone:** America/Phoenix
- **Rationale:** 3rd of month ensures all previous month data available (5-day API lag)

### Databricks Setup
- **Profile:** bidev (development)
- **Cluster:** Single-node, i3.xlarge
- **Output:** Delta table `climate_demo.monthly_arizona_weather`

---

## Key Comparison Points

### Claude Code Context System
- `CLAUDE.md` at repo root (700+ lines)
- `.claude/agents/` - 4 specialized agents (code-review, sql-quality, qc-validator, docs-review)
- `.claude/commands/` - 6 workflow commands (/save-work, /review-work, /merge-work, etc.)
- CLI-native: direct access to `databricks`, `aws`, `snow`, `acli`, `gh`

### Cursor Context System
- `AGENTS.md` at repo root (same content as CLAUDE.md, universal standard)
- `.cursorrules` or `.cursor/rules/` for Cursor-specific rules
- Agent mode for multi-step task execution
- IDE-native: embedded terminal, inline diffs, visual file tree

### AGENTS.md Facts
- Open standard under Linux Foundation (Agentic AI Foundation)
- 60,000+ open-source projects use it
- Supported by 20+ tools: Cursor, Codex, Gemini CLI, Copilot, Windsurf, etc.
- "README for AI agents" - separates agent instructions from human docs
- Nearest-file hierarchy for monorepos

---

## Databricks CLI Quick Reference

```bash
# Job management
databricks jobs create --json @config.json
databricks jobs list
databricks jobs run-now <JOB_ID>
databricks jobs get-run <RUN_ID>

# File operations
databricks fs cp script.py dbfs:/jobs/climate_data_refresh/

# Workspace
databricks workspace list /
databricks current-user me
```

---

## Demo Prompt (Used in Both Tools)

```
I need to set up automated climate data collection for Arizona. Here's what I need:

1. Research what free climate data APIs are available (prefer no authentication required)
2. Create a Python script that fetches monthly weather data for 10 Arizona cities
3. Create a Databricks job configuration (scheduled 3rd of month, 6 AM Phoenix time)
4. The script should aggregate daily data to monthly statistics
5. Include error handling and data validation

Store everything in this folder with a README documenting the solution.
```

---

## Script Generation

Use `/generate-script-outline videos/claude_code_vs_cursor` to generate the initial script from this CLAUDE.md and the README.md.
