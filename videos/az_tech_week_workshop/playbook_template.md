# Context Engineering Playbook Template

Use this template during the workshop exercise. Pick your example scenario, fill in each step, then paste the result into your AI coding tool.

---

## Step 0: Pick Your Example Scenario

Choose the one closest to your daily work, or bring your own:

| # | Example Scenario | If this sounds like you... |
|:--|:----------|:--------------------------|
| 1 | **Automate a recurring report** | You regularly pull data, summarize it, and send it to someone |
| 2 | **Triage incoming requests** | You have a backlog of items to categorize, prioritize, or route |
| 3 | **Build a simple app or tool** | You need an internal calculator, form, dashboard, or utility |
| 4 | **Draft communications from raw info** | You turn notes, data, or context into polished messages |
| 5 | **Build or optimize a website** | You need a landing page, portfolio site, or want to improve an existing one |

**My example scenario:** _______________

---

## Step 1: Define Your AI Assistant's Role

Tell the AI who it is and what it's good at. This is the **Instructions** layer of Context Engineering.

**Template:**
```
You are a [role] who specializes in [domain].
You help with [specific tasks].
Your standards are [quality expectations].
```

**Examples by scenario:**

| Example Scenario | Example Role |
|:----------|:-------------|
| Recurring report | "You are a data analyst who specializes in business reporting. You produce concise, data-driven summaries for leadership." |
| Triage requests | "You are an operations specialist who categorizes and prioritizes incoming requests by urgency and routes them to the right team." |
| Build an app | "You are a software developer who builds simple, functional internal tools from plain-English descriptions." |
| Draft communications | "You are a communications specialist who turns raw notes and data into polished, professional messages." |
| Build a website | "You are a web developer who creates fast, clean, professional websites that look great on any device." |

**My role definition:**

```
You are a _______________
who specializes in _______________.
You help with _______________.
Your standards are _______________.
```

---

## Step 2: Describe Your Business Problem

Tell the AI what you need done. Be specific about inputs, outputs, and constraints. This is the **Structure** layer.

**Answer these questions:**

1. **What's the input?** (a spreadsheet, a list of tickets, meeting notes, a project idea, etc.)

   _____________________________________________

2. **What does "done" look like?** (a summary email, a categorized list, a deployed app, a polished message, etc.)

   _____________________________________________

3. **What constraints matter?** (format requirements, audience, tone, deadline, tools you use, etc.)

   _____________________________________________

4. **What are the specific steps?** (list 3-5 things you want the AI to do)

   1. ___________________________________________
   2. ___________________________________________
   3. ___________________________________________
   4. ___________________________________________
   5. ___________________________________________

---

## Step 3: Give It Context

This is the most important step — and the one most people skip. Tell the AI what it needs to know to do the job well. This is the **Tools** layer.

**What context does the AI need?**

- [ ] **Data or files** — What data should it work with? (CSV, spreadsheet, database, API)
- [ ] **Examples** — Can you show it what good output looks like?
- [ ] **Rules or standards** — Are there formatting rules, naming conventions, or business rules?
- [ ] **Tool connections** — Does it need to connect to a system? (Google Sheets, Jira, GitHub, database)
- [ ] **Background knowledge** — Does it need to understand your industry, company, or audience?

**My context:**

```
Here's what you need to know:

Data source: _______________
Output format: _______________
Key rules: _______________
Tools to use: _______________
Additional context: _______________
```

---

## Step 4: Run It

Combine Steps 1-3 into a single prompt and paste it into your AI coding tool. Then iterate.

**Your complete prompt:**

```
[Paste your role definition from Step 1]

[Paste your problem description from Step 2]

[Paste your context from Step 3]
```

**After running it:**

- Did the AI understand the problem? If not, add more context (Step 3).
- Is the output format right? If not, be more specific about what "done" looks like (Step 2).
- Is the quality right? If not, refine the role and standards (Step 1).
- Want to make this repeatable? Save your prompt as a file in your project — that's the **Workflows** layer.

---

## Tips

- **Start simple, then iterate.** Your first prompt doesn't need to be perfect. Run it, see what happens, refine.
- **More context = better results.** The AI can't read your mind. If it gets something wrong, it probably needs more context, not a better prompt.
- **Save what works.** If you write a prompt that works well, save it as a markdown file in your project. Now it's a reusable workflow.
- **Ask the AI for help writing the prompt.** You can literally say "Help me write a prompt that does X" — the AI is good at this.

---

## After the Workshop

1. **Save your playbook** — Keep your completed template as a starting point
2. **Create a CLAUDE.md or AGENTS.md** — Put your role definition and standards in your project root
3. **Try a tool connection** — Connect your AI to one of your actual work systems (Google Sheets, Jira, GitHub, etc.)
4. **Watch the deep dives** — [Claude Code Deep Dive](https://www.youtube.com/watch?v=g4g4yBcBNuE) | [Free AI Data Analysis](https://youtu.be/bWEs8Umnrwo)
5. **Star this repo** — [github.com/kyle-chalmers/data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template)
