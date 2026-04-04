# Archetype Demo Prompts

Starter prompts for each demo archetype. Designed to be adapted live based on audience input — not rigid scripts. Each applies the Context Engineering framework (role + problem + context + tool connection).

---

## Archetype 1: Automate a Recurring Report

**Tool connection:** Notion MCP (primary) or Google Sheets via Python (backup)

**With Notion MCP (Official):**

```text
You are a data analyst who specializes in business reporting. You produce concise,
data-driven summaries for leadership.

I have customer feedback data in a Notion database that I need to summarize every week.
The database has about 50 entries with dates, categories, ratings, and free-text comments.

Can you help me:
1. Connect to my Notion database and pull the feedback data
2. Categorize the feedback by theme (product, service, pricing, support, etc.)
3. Calculate average ratings by category
4. Identify the top 3 issues and top 3 positive trends
5. Draft a summary email I can send to the leadership team

The output should be concise, data-driven, and ready to send.
```

**With Google Sheets via Python (backup — no official MCP, use CLI/Python instead):**

```text
You are a data analyst who specializes in business reporting. You produce concise,
data-driven summaries for leadership.

I have customer feedback data in a Google Sheet that I need to summarize every week.
There's no official Google Sheets MCP, so use Python (gspread library) to connect
to the sheet and pull the data.

Can you help me:
1. Connect to my Google Sheet using gspread and pull the feedback data
2. Categorize the feedback by theme (product, service, pricing, support, etc.)
3. Calculate average ratings by category
4. Identify the top 3 issues and top 3 positive trends
5. Draft a summary email I can send to the leadership team

The output should be concise, data-driven, and ready to send.
```

**With LinkedIn data (alternative):**

```text
You are a data analyst who specializes in professional network analysis.

I have my LinkedIn connections export (Connections.csv) with 3,700+ connections
including names, companies, positions, and connection dates.

Can you help me:
1. Load the CSV and explore the data
2. Show my connection growth over time (by month/year)
3. Identify the top 10 companies in my network
4. Break down connections by industry or role type
5. Draft a "network health report" summary

Use DuckDB or pandas to analyze the data. Show me visualizations if possible.
```

---

## Archetype 2: Triage Incoming Requests

**Tool connection:** Atlassian/Jira MCP (primary) or local CSV (backup)

**With Jira MCP:**

```text
You are an operations specialist who helps triage and categorize incoming requests.
You prioritize by urgency and route items to the right team.

I have open tickets in my Jira project that need to be categorized and prioritized.

Can you help me:
1. Connect to Jira and pull the open tickets from the KAN project
2. Categorize each by type (bug, feature request, question, complaint)
3. Assign priority (critical, high, medium, low) based on the description
4. Group by category and present a summary of what needs attention first
5. Draft routing recommendations for each category

Focus on the tickets that need immediate action.
```

**With Support Tickets CSV (backup):**

```text
You are an operations specialist who helps triage and categorize incoming requests.
You prioritize by urgency and route items to the right team.

I have a CSV file of support tickets at:
videos/az_tech_week_workshop/datasets/support_tickets.csv

Can you help me:
1. Load the CSV and explore what columns are available
2. Categorize tickets by type based on the description text
3. Assess priority based on the content (critical, high, medium, low)
4. Group by category and present a summary of what needs attention first
5. Draft routing recommendations

Use DuckDB or pandas to analyze. Focus on the most urgent items.
```

---

## Archetype 3: Build a Simple App or Tool

**Tool connection:** GitHub CLI + filesystem (primary), Vercel CLI for deploy

```text
You are a software developer who helps build simple, functional internal tools.
You create applications from plain-English descriptions that work on day one.

I need a [AUDIENCE MEMBER DESCRIBES THEIR TOOL NEED].

Can you help me:
1. Create the project structure for a simple web app
2. Build the core functionality based on what I described
3. Add a clean, simple interface that anyone on my team can use
4. Test it locally to make sure it works
5. Deploy it to a live URL using Vercel so I can share it with my team

Keep it simple and functional. I want something usable today, not perfect.
Use Next.js with TypeScript and Tailwind CSS.
```

**If no audience input, use this default:**

```text
You are a software developer who helps build simple, functional internal tools.

I need a tip calculator for our restaurant team. It should:
- Let servers enter the bill total and number of people
- Calculate tip amounts at 15%, 18%, 20%, and 25%
- Show per-person split for each tip level
- Work on mobile phones (responsive)
- Have a clean, simple interface

Can you help me:
1. Create the project with Next.js
2. Build the calculator logic and interface
3. Test it locally
4. Deploy it to Vercel

Keep it simple — this should take under 10 minutes.
```

---

## Archetype 4: Build or Optimize a Website

**Tool connection:** GitHub CLI + Vercel CLI

```text
You are a web developer who specializes in building fast, professional websites.
You create clean, responsive sites that look great on any device.

I need to [AUDIENCE MEMBER DESCRIBES THEIR WEBSITE NEED].

Can you help me:
1. Set up a new Next.js project
2. Build the page layout with the content I described
3. Make it responsive and fast-loading
4. Style it professionally with Tailwind CSS
5. Deploy it to a live URL using Vercel

I want something I can show people today. Keep it clean and professional.
```

**If no audience input, use this default:**

```text
You are a web developer who specializes in building fast, professional websites.

I need a personal landing page for my consulting business. It should have:
- A hero section with my name, title, and a brief tagline
- A section listing my 3 core services
- A "Contact Me" section with an email link
- Clean, modern design with a dark theme
- Mobile responsive

Can you help me:
1. Set up a new Next.js project
2. Build the landing page with these sections
3. Style it with Tailwind CSS
4. Deploy it to Vercel with a live URL

I want to show this to a potential client today.
```

---

## Wild Card Adaptation Template

When the audience suggests their own problem, use this structure:

```text
You are a [ROLE based on their problem] who specializes in [THEIR DOMAIN].
You help with [WHAT THEY DESCRIBED].

[RESTATE THEIR PROBLEM IN STRUCTURED FORM]

Can you help me:
1. [First logical step based on their input]
2. [Second step]
3. [Third step]
4. [Fourth step]
5. [Show the output / deploy / deliver]

[ANY CONSTRAINTS THEY MENTIONED]
```

**Tips for adapting live:**
- Ask the audience member: "What tool do you use for this today?" (determines tool connection)
- Ask: "Who receives the output?" (determines format)
- Ask: "What makes this tedious?" (determines the value-add)
