# Demo Prompts

Prompts used during recording. Both tools receive the same Databricks job prompt. The AGENTS.md prompt is for on-camera creation of the AGENTS.md file.

---

## Databricks Job Prompt (Used in Both Tools)

Give this exact prompt to both Claude Code and Cursor:

```
I need to set up automated climate data collection for Arizona. Here's what I need:

1. Research what free climate data APIs are available (prefer no authentication required)
2. Create a Python script that fetches monthly weather data for 10 Arizona cities
3. Create a Databricks job configuration (scheduled 3rd of month, 6 AM Phoenix time)
4. The script should aggregate daily data to monthly statistics
5. Include error handling and data validation

Store everything in this folder with a README documenting the solution.
```

### What to Narrate During the Demo

**Research phase:** "Notice how it's evaluating different APIs... it chose Open-Meteo because it's free and needs no authentication."

**Script creation:** "It's writing production Python - error handling, logging, data validation. These patterns come from the instructions in [CLAUDE.md / AGENTS.md]."

**Job config:** "The cron schedule is set for the 3rd of the month. That's deliberate - Open-Meteo has a 5-day data lag, so running on the 3rd ensures the full previous month is available."

**Documentation:** "It creates a README automatically because the context file says to document everything."

---

## AGENTS.md Creation Prompt (On-Camera)

Use this prompt during recording to demonstrate creating the AGENTS.md file:

```
I want to create an AGENTS.md file at the root of this repository. AGENTS.md is an
open standard (agents.md) supported by 20+ AI coding tools including Cursor, Codex,
Gemini CLI, and GitHub Copilot. It serves as a "README for AI agents."

I already have a CLAUDE.md file that serves as the instruction set for Claude Code.
I want AGENTS.md to contain the same content so that non-Claude tools (like Cursor)
get the same project context.

Please:
1. Read the existing /CLAUDE.md file
2. Create /AGENTS.md with the same content
3. Do NOT modify the existing CLAUDE.md

The CLAUDE.md remains the "brain" for Claude Code. The AGENTS.md becomes the "brain"
for everything else.
```

---

## Pre-Recording Setup

Before recording either demo:

1. Clean the target demo_workspace directory:
   ```bash
   # For Claude Code demo
   rm -rf videos/claude_code_vs_cursor/demo_workspace/claude_code/*
   touch videos/claude_code_vs_cursor/demo_workspace/claude_code/.gitkeep

   # For Cursor demo
   rm -rf videos/claude_code_vs_cursor/demo_workspace/cursor/*
   touch videos/claude_code_vs_cursor/demo_workspace/cursor/.gitkeep
   ```

2. Verify Databricks CLI works:
   ```bash
   databricks workspace list /
   ```

3. Verify Open-Meteo API accessible:
   ```bash
   curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2025-01-01&end_date=2025-01-05&daily=temperature_2m_max" | head -c 200
   ```

4. Terminal settings: 18-20pt font, dark theme, notifications OFF
