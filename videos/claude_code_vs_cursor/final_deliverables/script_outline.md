# Claude Code vs Cursor: Context Engineering for AI Coding Tools - Video Script

**Total Estimated Runtime:** 18-22 minutes

---

## HOOK INTRO (90-120 seconds)

### First 5 Seconds
*(Standing, high energy, direct to camera)*

**Option 1:**
- "Claude Code or Cursor - I built the same thing with both. Here's what actually matters."

**Option 2:**
- "Everyone's debating which AI coding tool is best. They're asking the wrong question."

**Option 3:**
- "I gave Claude Code and Cursor the exact same task. The winner? Neither. Let me explain."

### 6-15 Seconds
*(Set expectations)*

- "In this video, I'm building the exact same Databricks job with Claude Code and Cursor - same prompt, same task, two very different tools. But the real story isn't which tool is better. It's about something called context engineering, and a file called AGENTS.md that most people have never heard of."

### Rest of Intro (Build credibility and preview)

- Your angle: "I've been using Claude Code for over a year in my day job as a data engineer. I have a 700-line CLAUDE.md file that tells it everything about my codebase, my tools, my standards. Recently I tried Cursor, and I discovered something interesting - most of that context transfers over through a universal standard called AGENTS.md."

- [Personal anecdote opportunity: What specifically made you want to try Cursor? Was it a colleague, an article, curiosity?]

- Preview the structure:
  - "First, I'll explain AGENTS.md - a new open standard that 60,000 projects already use"
  - "Then I'll build an Arizona weather data pipeline with Claude Code"
  - "Then I'll build the same thing with Cursor"
  - "And finally, we'll put them head to head and talk about when to use which"

- "Whether you're already using one of these tools or trying to decide, you'll walk away knowing how to make ANY AI coding tool more effective."

**Section Transition:**
- "Let's start with the standard that makes all of this work."

---

## DEFINITIONS (45-60 seconds)

- "Before we dive in, a few terms you'll hear throughout:"

- **Context Engineering** - "The practice of structuring your project so AI tools actually understand what you're working on. Think of it as writing a briefing document for a very capable new team member."

- **AGENTS.md** - "An open standard instruction file that works across 20+ AI coding tools. One file, many tools."

- **CLAUDE.md** - "Claude Code's version - same idea, but Claude-specific."

- **.cursorrules** - "Cursor's version - project rules tailored for Cursor."

- **Open-Meteo API** - "A free weather data API we'll use in the demo. No authentication needed."

- "Full definitions and links in the description."

**Section Transition:**
- "Alright, let's talk about AGENTS.md - the file that changes everything about how you set up AI tools."

---

## SECTION 1: AGENTS.md - The Universal Standard (2-3 minutes)

### What Is AGENTS.md? (60-90 seconds)

[Show on screen: agents.md website]

- "AGENTS.md is an open standard maintained by the Agentic AI Foundation under the Linux Foundation. Think of it as a README, but for AI agents instead of humans."

- "Your README tells a human developer how to set up and contribute to your project. Your AGENTS.md tells an AI agent the same thing - build commands, testing procedures, code conventions, project structure."

- "And here's the key: over 60,000 open-source projects already use it, and more than 20 tools support it natively."

[Show on screen: List of supported tools - Cursor, OpenAI Codex, Google Gemini CLI, GitHub Copilot, Windsurf, Devin, and more]

- Key insight: "One AGENTS.md file works across Cursor, Codex, Gemini CLI, Copilot, Windsurf, and more. Write it once, use it everywhere."

### How I Use It (30-45 seconds)

[Show on screen: Repository root showing both CLAUDE.md and AGENTS.md]

- "In my repository, I have two files at the root: CLAUDE.md and AGENTS.md."

- "CLAUDE.md is the brain for Claude Code. It's 700+ lines of instructions - my role, my tools, my coding standards, my workflow conventions."

- "AGENTS.md is the brain for everything else. It contains the same content, so when I open this project in Cursor, or Codex, or any other tool, they get the same context."

- [Personal anecdote opportunity: How did you discover AGENTS.md? What made you decide to adopt it?]

### Nearest-File Hierarchy (20-30 seconds)

- "For monorepos, AGENTS.md supports a hierarchy - the nearest file in the directory tree takes precedence. So you can have a root-level AGENTS.md for the whole project, and specific ones in subdirectories for different packages."

- "OpenAI's main repository has 88 AGENTS.md files across their packages."

**Section Transition:**
- "So that's the foundation. Now let's put it to the test with a real task."

---

## SECTION 2: The Task - Building a Databricks Job (60-90 seconds)

### Background (20-30 seconds)

[Show on screen: AZ Emerging Tech Meetup slide or README]

- "I did this exact task live at the Arizona AI and Emerging Tech Meetup back in January. It was Demo 2 of my presentation - showing that AI can handle infrastructure and ETL tasks, not just analysis."

- "Today I'm redoing it from scratch with both tools."

### The Task (30-45 seconds)

[Show on screen: The demo prompt from instructions/demo_prompt.md]

- "We're building a Databricks job that:
  1. Pulls monthly weather data for 10 Arizona cities from the Open-Meteo API
  2. Aggregates daily data into monthly statistics - temperature, precipitation, wind, humidity
  3. Runs on a schedule - the 3rd of each month at 6 AM Phoenix time"

- "Open-Meteo is free, no authentication required - perfect for demos."

### The Rules (15-20 seconds)

- "Same prompt to both tools. I'm not going to coach either one. Let's see what they produce."

[Show on screen: Side-by-side prompt ready to go in both tools]

**Section Transition:**
- "First up: Claude Code."

---

## SECTION 3: Claude Code Demo (5-6 minutes)

### Context Engineering Setup (90-120 seconds)

[Show on screen: Terminal, CLAUDE.md file open]

- "Before I even type a prompt, let me show you what Claude Code already knows about this project."

[Show on screen: Quick scroll through CLAUDE.md sections - role, tools, standards]

- "My CLAUDE.md is 700+ lines. It defines my role as a Senior Data Engineer, lists every CLI tool I have installed - Snowflake, Databricks, Jira, AWS, GitHub - and sets coding standards, QC requirements, documentation patterns."

- "But that's just the foundation."

[Show on screen: .claude/agents/ directory listing]

- "I also have custom agents. A code review agent, a SQL quality agent, a QC validator, a docs reviewer. These are specialized AI agents I can invoke for specific tasks."

[Show on screen: .claude/commands/ directory listing]

- "And custom commands - /save-work commits and pushes, /review-work runs quality agents, /initiate-request sets up a new project from scratch."

- Key insight: "Claude Code isn't just an AI assistant - it's a complete workflow system. CLAUDE.md plus agents plus commands equals end-to-end automation."

- [Personal anecdote opportunity: How long did it take to build this system? How has it evolved over time?]

### Running the Demo (3-4 minutes)

[Show on screen: Terminal with Claude Code active]

- "Let me give Claude the prompt."

[Show on screen: Pasting the demo prompt]

*(Narrate as Claude works - use time-lapse editing for slower parts)*

- "Notice it's starting by researching the API... it evaluates options and picks Open-Meteo because it's free and needs no auth."

[Show on screen: Claude creating Python script]

- "Now it's writing the Python script. Watch the patterns - error handling, logging, data validation. These come directly from my CLAUDE.md coding standards."

[Show on screen: Claude creating job_config.json]

- "The job config... cron schedule set to the 3rd of the month. That's not random - the API has a 5-day data lag, so running on the 3rd ensures the full previous month is available. That's the kind of reasoning you get from a well-configured AI."

[Show on screen: Claude creating README.md]

- "And documentation. My CLAUDE.md says to always create a README, so it does."

- [Personal anecdote opportunity: Compare to the meetup experience - faster? Better? Different approach?]

### Key Observations (30-60 seconds)

- "What I want you to notice:"
  - "Claude had direct CLI access - it could test the API right from the terminal"
  - "It followed my coding standards from CLAUDE.md without me having to remind it"
  - "Error handling patterns match what I specified"
  - "Documentation was automatic because the context file said to create it"

[Show on screen: Final file listing in demo_workspace/claude_code/]

**Section Transition:**
- "That's Claude Code. Now let's see how Cursor handles the exact same task."

---

## SECTION 4: Cursor Demo (5-6 minutes)

### Context Engineering Setup (90-120 seconds)

[Show on screen: Cursor IDE with project open]

- "For Cursor, the context engineering works differently. Let me show you the setup."

[Show on screen: AGENTS.md file in Cursor]

- "Cursor automatically reads the AGENTS.md file. Same content as my CLAUDE.md - role definition, coding standards, tool references, QC requirements. Cursor picks this up out of the box."

[Show on screen: .cursorrules file if created]

- "I also created a cursorrules file for any Cursor-specific instructions."

- "But here's what I could NOT bring over:"

[Show on screen: Comparison graphic or split screen]

- "Custom agents? Claude Code only. Custom commands like /save-work and /review-work? Claude Code only. Those don't exist in Cursor's ecosystem."

- "So Cursor gets the context - the knowledge and standards - but not the workflow automation."

- [Personal anecdote opportunity: What was the experience like setting up Cursor compared to Claude Code?]

### Running the Demo (3-4 minutes)

[Show on screen: Cursor with Agent mode selected]

- "I'll use Cursor's Agent mode - that's their most capable mode for multi-step tasks."

[Show on screen: Pasting the same demo prompt]

*(Narrate as Cursor works - use time-lapse editing for slower parts)*

- "Cursor is processing the request... it's reading the AGENTS.md for context."

[Show on screen: Cursor creating files]

- "Watch how it creates the files - you can see the inline diffs in the IDE, which is a nice visual feedback that Claude Code's terminal doesn't give you."

- "The Python script is taking shape..."

[Show on screen: Cursor handling the job config]

- "Job configuration coming together..."

- [Personal anecdote opportunity: What surprised you about the Cursor experience? What was better or worse than expected?]

### Key Observations (30-60 seconds)

- "What stands out with Cursor:"
  - "IDE integration gives you visual feedback - inline diffs, file tree updates, syntax highlighting in real time"
  - "It read the AGENTS.md and followed the standards"
  - "Terminal access works but it's embedded in the IDE, not native"
  - "[Specific observation about code quality/approach difference]"

[Show on screen: Final file listing in demo_workspace/cursor/]

**Section Transition:**
- "Both tools completed the task. Now the interesting part - let's put them head to head."

---

## SECTION 5: Head-to-Head Comparison (3-4 minutes)

### Side-by-Side Code Review (60-90 seconds)

[Show on screen: Split screen - Claude Code output left, Cursor output right]

- "Let's look at the Python scripts side by side."

[Show on screen: Highlighting key differences in code structure]

- "Code structure and organization: [specific comparison]"
- "Error handling approach: [specific comparison]"
- "Documentation quality: [specific comparison]"

- Key insight: "Both tools produced working code because they both had the context they needed. The differences are in approach, not quality."

### The Comparison Framework (90-120 seconds)

[Show on screen: Animated comparison table graphic]

| Dimension | Claude Code | Cursor |
|-----------|-------------|--------|
| Context System | CLAUDE.md (700+ lines) | AGENTS.md + .cursorrules |
| Custom Agents | 4 specialized agents | No equivalent |
| Custom Commands | 6 workflow shortcuts | No equivalent |
| Tool Access | CLI-native (direct) | IDE terminal (embedded) |
| Environment | Terminal | VS Code fork |
| Visual Feedback | Text-based | Inline diffs, file tree |

- "Context engineering: Both tools got the same foundation through their respective context files. Claude Code gets extra depth through agents and commands."

- "Tool access: Claude Code runs in the terminal with native access to every CLI tool - Databricks, AWS, Snowflake, Jira, GitHub. Cursor accesses the terminal through the IDE, which works but adds a layer."

- "Workflow automation: This is Claude Code's biggest advantage. Custom agents for code review, QC validation, docs review. Custom commands for saving work, reviewing work. Cursor has nothing equivalent."

- "Developer experience: Cursor's advantage is the IDE. Inline diffs, visual file tree, integrated debugging. If you live in VS Code, Cursor feels natural. If you live in the terminal, Claude Code feels natural."

### When to Use Which (60-90 seconds)

- "So when should you use which?"

- "Claude Code if you: work heavily with CLI tools, want end-to-end workflow automation, prefer the terminal, need to orchestrate across multiple platforms - Jira, Snowflake, Databricks, GitHub in one conversation."

- "Cursor if you: prefer IDE integration, want visual feedback on changes, work primarily in a single codebase, value the VS Code ecosystem."

- "Or - and this is what I do - use both. AGENTS.md means your context engineering works across all of them."

- Key insight: "The tool matters less than the context you give it. Invest in your AGENTS.md and CLAUDE.md files. That's where the 10x productivity comes from - not the tool itself."

- [Personal anecdote opportunity: Which do you actually prefer day-to-day and why? Be honest about the tradeoffs.]

**Section Transition:**
- "Let me wrap up with what I think you should actually do with this information."

---

## WRAP-UP (60-90 seconds)

### Recap the Key Takeaways

- "To recap: we introduced AGENTS.md - a universal standard used by 60,000 projects and supported by 20+ AI tools. We built the same Databricks weather job with both Claude Code and Cursor. And we compared how each tool handles context engineering, tool access, and workflow automation."

### What Should You Do Next?

- "Now you may ask yourself, all this information is great, but what should I do about it?"

  1. "First: Create an AGENTS.md file in your project. Even if you only use one tool today, you're future-proofing your context engineering for whatever tool comes next."

  2. "Second: Invest time in your context files. Whether it's CLAUDE.md, AGENTS.md, or cursorrules - the more specific your instructions, the better your results. My 700-line file didn't happen overnight. Start with your role, your tools, and your coding standards."

  3. "Third: Try both tools on the same task, like I did. You'll quickly learn which fits your workflow."

### Closing

- "The AI coding tool wars are just getting started. But the real competitive advantage isn't the tool - it's how well you engineer the context around it."

- "If you found this useful, like and subscribe - I'm creating more content on AI-assisted data engineering workflows."

- "Let me know in the comments which tool you prefer and why. I'd love to hear about your experience."

- "As always, thanks so much and I will talk to you next time."

---

## PRODUCTION NOTES

**B-Roll Needed:**
- Claude Code terminal session (full demo, uncut for editing)
- Cursor IDE session (full demo, uncut for editing)
- CLAUDE.md scrolling through sections
- AGENTS.md file in both repo root and Cursor
- agents.md website
- Side-by-side code comparison (split screen)
- Comparison table graphic (animated or static)
- .claude/agents/ and .claude/commands/ directory listings

**Graphics Needed:**
- Key terms overlay
- Comparison table (5-dimension framework)
- AGENTS.md ecosystem diagram (supported tools)
- Context engineering architecture diagram (AGENTS.md + CLAUDE.md + .cursorrules)
- Task specification visual

**Screen Recording Checklist:**
- [ ] Claude Code full demo (uncut for editing)
- [ ] Cursor full demo (uncut for editing)
- [ ] CLAUDE.md walkthrough (scroll through key sections)
- [ ] AGENTS.md walkthrough
- [ ] .cursorrules walkthrough (if created)
- [ ] agents.md website
- [ ] Side-by-side final output comparison
- [ ] .claude/agents/ directory listing
- [ ] .claude/commands/ directory listing
- [ ] Databricks CLI verification (bidev profile)

**Pre-Recording Setup:**
- [ ] Clean demo_workspace/claude_code/ folder (empty except .gitkeep)
- [ ] Clean demo_workspace/cursor/ folder (empty except .gitkeep)
- [ ] Verify Databricks CLI works (bidev profile)
- [ ] Verify Open-Meteo API accessible
- [ ] Cursor installed with AGENTS.md configured
- [ ] Terminal font 18-20pt, dark theme
- [ ] Notifications OFF on all devices
- [ ] Do a practice run of both demos before recording

**Editing Notes:**
- Use time-lapse for slow parts of demos (API calls, file generation)
- Focus narration on interesting moments (reasoning, tool differences)
- Both demos should be roughly equal screen time
- Split-screen comparison moments should be clearly edited
- Consider picture-in-picture for narration during demos
