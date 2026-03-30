# AZ Tech Week Workshop: The Practical AI Playbook

## Overview

**Event:** The Practical AI Playbook Workshop at AZ Tech Week
**Date:** Wednesday, April 8, 2026, 5:30 PM - 8:00 PM MST
**Venue:** 1951 @ SkySong, 1475 N Scottsdale Rd, Scottsdale, AZ 85257
**Role:** Kyle Chalmers — sole presenter and facilitator
**Audience:** ~30-40 attendees, mixed levels (practitioners, founders, leaders, students), all motivated to learn about AI tools
**Event page:** [https://partiful.com/e/VPy2EpNYQFppO6ZQA17n](https://partiful.com/e/VPy2EpNYQFppO6ZQA17n)

## Design: Context Engineering Playbook — Framework + Layered Demo + Personalized Exercise

Three-act structure delivering three takeaways:

1. Attendees install and use an AI coding tool (enabled by prerequisite video)
2. They understand the Context Engineering framework and can apply it to their own work
3. They leave with a playbook template and their own started project

---

## Workshop Agenda


| Block                   | Time      | Duration | Description                                                                                                                                                                        |
| ----------------------- | --------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Doors & Settle          | 5:30-5:45 | 15 min   | Arrive, connect to wifi, open laptops                                                                                                                                              |
| Welcome & Scene-Setting | 5:45-6:00 | 15 min   | Kyle's intro, what Context Engineering is (the "why"), audience pulse — who's used AI tools before?                                                                                |
| Framework Deep Dive     | 6:00-6:30 | 30 min   | The Context Engineering playbook: 4 layers (instructions, structure, tools, workflows) with concrete examples. Tool-agnostic framing — applies to Claude Code, Cursor, Codex, etc. |
| Live Demo               | 6:30-7:00 | 30 min   | Solve a tedious business workflow end-to-end showing the framework in action                                                                                                       |
| Break                   | 7:00-7:10 | 10 min   | Stretch, catch up, install tools if needed                                                                                                                                         |
| Guided Exercise         | 7:10-7:45 | 35 min   | Attendees apply the playbook template to their own business problem                                                                                                                |
| Showcase & Wrap         | 7:45-8:00 | 15 min   | 2-3 volunteers share what they built, key takeaways, resources                                                                                                                     |
| Networking              | 8:00+     | open     | Mingle, 1-on-1 help                                                                                                                                                                |


---

## Act 1: Framework Deep Dive (30 min)

**Goal:** Attendees understand that the difference between "AI is a toy" and "AI is a productivity multiplier" is context — and there's a repeatable framework for providing it.

**The 4 Layers of Context Engineering:**

1. **Instructions** — Defining the AI's role, expertise, rules, and standards (CLAUDE.md, .cursorrules, etc.)
2. **Structure** — Organizing your project so the AI can navigate it (folder conventions, naming, templates)
3. **Tools** — Connecting the AI to your actual work systems (CLIs, APIs, MCP servers, databases)
4. **Workflows** — Custom commands and repeatable patterns that encode your processes (slash commands, custom agents)

**Teaching approach:** Each layer gets ~7 minutes with a concrete before/after example showing the difference context makes. Use this repo's own CLAUDE.md as a real example for layer 1.

---

## Act 2: Live Demo (30 min)

**Concept: "Automate a Tedious Business Workflow"**

Take a universally relatable task — e.g., "I have 50 customer feedback entries in a CSV. Categorize them, extract themes, and draft a summary email to leadership."

**Why this demo:**

- Relatable to technical and non-technical attendees alike
- Shows AI as a practical work accelerator, not just a coding tool
- Demonstrates all 4 Context Engineering layers in action
- Has a visible, satisfying output (the summary email)
- Naturally shows iteration and human-in-the-loop refinement

**Demo flow:**

1. Show the raw problem (messy CSV, tedious manual work)
2. Show how Context Engineering makes the AI effective (role definition, data context, output format)
3. Run it live — categorize, extract themes, produce summary
4. Show the output, refine with follow-up prompts
5. Emphasize: "The magic isn't the tool — it's the context you gave it"

**Specific demo dataset and scenario TBD** — should be finalized closer to the event with realistic but non-sensitive data.

---

## Act 3: Guided Exercise (35 min)

**Goal:** Every attendee applies the Context Engineering framework to their own business problem.

**The Playbook Template** (provided as a markdown file in the companion repo):

Attendees work through 4 steps:

1. **Define your AI assistant's role** — "You are a [role] who specializes in [domain]. You help with [tasks]." (mirrors CLAUDE.md role section)
2. **Describe your business problem** — What's the input? What does "done" look like? What constraints matter?
3. **Give it context** — What files, data, examples, or rules does the AI need? (This is the "aha" moment)
4. **Run it** — Paste context + problem into their AI tool and see what happens. Iterate.

**Accommodation for mixed setup levels:**

- Tool installed: Work through all 4 steps live
- No tool installed: Complete steps 1-3 (the most valuable thinking exercise), test at home
- Advanced users: Extend with custom commands or tool integrations

**Facilitation:**

- Project a timer on screen
- Walk the room and help individuals
- Checkpoint at ~15 minutes — show a quick example of someone's work to keep momentum
- Encourage attendees to help neighbors

---

## Companion Materials

### Repository Location

`videos/az_tech_week_workshop/` in this repo (`data-ai-tickets-template`)

**Rationale:** This repo IS the Context Engineering reference implementation. It has the CLAUDE.md, folder structure, custom commands, and the January meetup materials. Attendees who star/clone it get the playbook template AND a working example of everything taught.

### Contents to Create

- `README.md` — Event overview, setup instructions, links to resources
- `playbook_template.md` — The 4-step exercise template attendees use during the workshop
- `demo_materials/` — Demo dataset and any supporting files
- `qr_codes/` — QR codes for repo, YouTube, LinkedIn (can reuse/update from January event)

---

## Prerequisite Video

**Publish:** Public on YouTube (KC Labs AI channel)
**Purpose:** Get attendees from "interested" to "laptop ready" before April 8

**Content scope:**

- Install at least one AI coding tool (Claude Code primary, Cursor and Codex as alternatives)
- Verify installation works with a simple test prompt
- Brief intro to Context Engineering (enough to prime them, not the full workshop)
- Think about the business problem to bring — prompting questions to help them pick one
- Star/clone the companion repo

**Framing:** Broadly useful ("Getting set up with AI coding tools") not narrowly event-specific. Pin a comment or add a card linking to the workshop event page.

**What the video is NOT:**

- A full Claude Code tutorial (existing channel content covers this)
- A deep dive into Context Engineering (that's the workshop)

**Target length:** 10-15 minutes

**Detailed video brief to be produced via `/video-brainstorm`.**

---

## Relationship to January Meetup

The January event (`videos/az_emerging_tech_meetup/`) was a 60-minute demo-focused presentation for a data-oriented audience. This workshop differs:


| Aspect      | January Meetup                                | April Workshop                                                  |
| ----------- | --------------------------------------------- | --------------------------------------------------------------- |
| Format      | Presentation + demos                          | Framework teach + demo + hands-on exercise                      |
| Duration    | 60 min                                        | 2.5 hours (including networking)                                |
| Audience    | Data professionals                            | Mixed (practitioners, founders, leaders, students)              |
| Takeaway    | "This is cool"                                | Playbook template + started project                             |
| Depth       | Context Engineering intro + 2 technical demos | Full framework + broadly relatable demo + personalized exercise |
| Tools shown | Claude Code + Snowflake/AWS/Databricks/Jira   | Tool-agnostic framework (Claude Code, Cursor, Codex)            |


---

## Open Items

- Finalize demo dataset and scenario (realistic but non-sensitive customer feedback data)
- Create playbook template markdown
- Build workshop slide deck (if using slides for framework section)
- Create/update QR codes
- Produce prerequisite video (via `/video-brainstorm` pipeline)
- Decide whether to use slides, terminal-only, or a mix during framework section
- Test full demo flow end-to-end before event

