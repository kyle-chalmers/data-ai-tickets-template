# Claude Code vs Cursor Video - Agent Context

Technical reference for AI agents working on this video project.

---

## Project Context

This video compares Claude Code and Cursor by building the same Databricks job with both tools. The task: automated monthly weather data collection for 10 Arizona cities using the Open-Meteo API.

## Demo Task

- **API:** Open-Meteo Historical Weather API (free, no auth)
- **Cities:** Phoenix, Tucson, Flagstaff, Mesa, Scottsdale, Tempe, Gilbert, Chandler, Yuma, Prescott
- **Output:** Python script + Databricks job config (scheduled 3rd of month, 6 AM Phoenix time)
- **Variables:** temperature, precipitation, wind speed, humidity (daily aggregated to monthly)

## Databricks CLI Reference

```bash
databricks jobs create --json @config.json
databricks jobs run-now <JOB_ID>
databricks fs cp script.py dbfs:/jobs/climate_data_refresh/
```

## Comparison Dimensions

1. Context Engineering System - CLAUDE.md vs AGENTS.md + .cursorrules
2. Tool Access - CLI-native vs IDE terminal
3. Workflow Automation - Custom agents/commands vs no equivalent
4. Code Generation Quality - Side-by-side assessment
5. Developer Experience - Terminal vs IDE tradeoffs
