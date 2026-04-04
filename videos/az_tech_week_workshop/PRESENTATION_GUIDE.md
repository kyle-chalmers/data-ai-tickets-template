# Presentation Guide — The Practical AI Playbook Workshop

Speaker-only notes. Not shown on screen — the README.md is the presentation material.

---

## Pre-Event Checklist

- [ ] Laptop charged and plugged in
- [ ] Terminal open with Claude Code ready
- [ ] README.md open in a browser tab (GitHub or local preview) for scrolling through
- [ ] All 6 tool connections verified working (Google Sheets MCP, Jira MCP, BigQuery CLI, GitHub CLI, Vercel CLI, DuckDB CLI)
- [ ] Demo datasets loaded (Coffee Shop Sales in Google Sheet, Support Tickets accessible)
- [ ] LinkedIn data in `linkedin_data/` folder locally
- [ ] Zoom link shared and recording started
- [ ] QR codes visible on screen or projected
- [ ] Wifi tested — have mobile hotspot as backup
- [ ] Water bottle nearby

---

## Block-by-Block Notes

### Doors & Settle (5:30-5:45)

- Mingle, help people find seats
- Have the README QR codes projected on screen so early arrivals can scan
- If people are setting up tools, point them to the install commands in the README

### Welcome & Framing (5:45-6:00)

**Audience Pulse Check (first 2-3 minutes):**

Ask these three questions with show of hands:

1. "How many of you watched the prerequisite video and got a tool installed?"
   - If <50%: mention the install commands are in the README, they can install during the demo
   - If >80%: great, move faster through setup references

2. "How many are using Claude Code? OpenCode? Something else like Cursor or Copilot?"
   - Note the distribution — useful when walking the room during the exercise

3. "How many have never used an AI coding tool before today?"
   - Calibrates how much hand-holding is needed

**No-tool fallback:** If many people don't have a tool, project the install commands on screen:
```bash
# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# OpenCode (free)
curl -fsSL https://opencode.ai/install | bash
```

**Framework Overview (remaining ~10 minutes):**

- Scroll to the "Context Engineering: The 4 Layers" section of the README
- Walk through each layer with one sentence each — don't deep dive
- Key phrase: "You're about to see all 4 in action, and then you'll apply them yourself."
- Mention the proof points naturally: "I built my website, an SMS app, and my entire video production pipeline with this same approach"

### Live Demo — Audience-Polled (6:00-6:35)

**The Poll (~2 min):**
- Scroll to "Vote on the Archetype" in the README
- Read each option, ask for show of hands or applause
- If vote is split, go with the loudest reaction
- If wild card gets energy, ask the person to describe their problem in 30 seconds

**Getting Details (~3 min):**
- "Who has a real version of this? What's your data look like? Who receives the output?"
- Use their specific details to make the demo personal
- If details are thin, fall back to the prepared scenario in the demo prompts

**Building the Playbook Live (~20 min):**
- Open Claude Code in terminal
- Narrate as you go: "First, I'm defining the role — that's the Instructions layer..."
- Show the tool connection moment explicitly: "Now watch — the AI is connecting to [tool] directly"
- Let the AI work, show the output, refine with follow-ups
- Keep it conversational, not scripted

**Call Out the Framework (~2 min):**
- "Did you notice what just happened? We used all 4 layers."
- Quick recap: which layer was which in the demo

**Buffer (~8 min):**
- Take questions from the audience about what they just saw
- If the demo ran fast, do a quick second iteration or show a different angle

**BACKUP PLAN:** If the chosen archetype's tool connection fails, pivot to Archetype 1 (Google Sheets). It's the most rehearsed and has the strongest visual payoff.

### Guided Exercise (6:35-7:05)

**Kickoff (~3 min):**
- Scroll to "Guided Exercise" section in README
- "Pick the archetype closest to your work. If none fit, bring your own."
- Point to the playbook template: "This is your guide — follow Steps 0 through 4."
- "If you don't have a tool installed, do Steps 0-3 — that's the most valuable thinking. Get help during open time."

**Walking the Room (~25 min):**
- Move around, check in with people
- Use the archetype as a conversation starter: "Which one did you pick? What's your problem?"
- Common sticking points:
  - Step 1 (Role): People make it too generic. Help them be specific.
  - Step 3 (Context): People skip this. Ask "what does the AI need to know that isn't obvious?"
  - Step 4 (Run it): If output is bad, it's usually a Step 3 problem.

**Checkpoint at ~15 min:**
- Quick pulse: "How's everyone doing? Anyone get a result they want to share?"
- If someone has something good, have them show their screen briefly (30 seconds)

### Wrap & Resources (7:05-7:10)

- Scroll to "Key Takeaways" section
- Quick recap: "The framework is 4 layers — Instructions, Structure, Tools, Workflows."
- Scroll to QR codes: "Scan these to stay connected."
- Mention the Saturday hike: "If you want to keep the conversation going..."
- Transition: "We're in open time now. Who built something they want to share?"

### Open Time & Networking (7:10-8:00+)

- First activity: "Who wants to share?" — have 1-2 volunteers show their screen
- Then float around for 1-on-1 help
- Priority: help people who are close to a working result
- For advanced users: help them set up a real tool connection (MCP or CLI)
- For beginners: help them complete Steps 0-3 and understand the framework

---

## Timing Adjustments

| If you're running... | Do this |
|:---------------------|:--------|
| **Behind by 5+ min** | Shorten the demo Q&A buffer. Skip the exercise checkpoint. |
| **Behind by 10+ min** | Cut the exercise to 20 min. More time in open networking compensates. |
| **Ahead of schedule** | Extend the demo with a second iteration. Or start the exercise early and give more time. |
| **Demo fails** | Pivot to backup (Archetype 1 / Google Sheets). Acknowledge it naturally — "This is live, things break. Let me show you the backup." |
| **Low energy in room** | Ask a direct question to someone specific. Or do a quick "turn to your neighbor" moment. |

---

## Key Phrases to Use

- "The difference between 'AI is a toy' and 'AI is a productivity multiplier' is the context you give it."
- "Think of it like onboarding a new team member."
- "The magic isn't the tool — it's the context."
- "More context, better results. If the output is wrong, give it more context."
- "You don't need to be a developer to use these tools."

---

## Key Phrases to Avoid

- Don't say "demo" or "for the video" or "for the audience" — this is being recorded
- Don't reference the presentation guide or CLAUDE.md on camera
- Don't say "as planned" or "per the script" — everything should feel natural
- Don't oversell — let the results speak for themselves
