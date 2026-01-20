<objective>
Review and improve the existing presentation materials for the Arizona AI & Emerging Technology Meetup talk titled "The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows" scheduled for January 21, 2026.

The presentation should showcase how Claude Code integrates with Snowflake, Jira, Databricks, GitHub, and AWS to create 10x productivity gains for data professionals. The target audience is ~123 technical data engineers and professionals.

**Critical constraint:** The presentation content should be ~40 minutes to allow ample time for Q&A. Better does NOT mean longer - prioritize clarity and impact over comprehensiveness.
</objective>

<context>
Event details:
- Date: Wednesday, January 21, 2026, 6:00 PM - 7:00 PM MST
- Venue: 1951@SkySong, 1475 N. Scottsdale Road, Room 151, Scottsdale, AZ
- Meetup URL: https://www.meetup.com/azemergingtech/events/312526569/
- Speaker: Kyle Chalmers

This repository contains the actual tool integrations to demo:
- Custom commands in `.claude/commands/` (initiate-request, save-work, review-work, merge-work, etc.)
- Custom agents in `.claude/agents/` (code-review-agent, sql-quality-agent, qc-validator-agent, docs-review-agent)
- CLAUDE.md with comprehensive context engineering patterns
- Existing video materials in `videos/` folder showing individual integrations

Review the existing materials to understand the integration patterns:
@.claude/commands/initiate-request.md
@.claude/commands/save-work.md
@.claude/commands/review-work.md
@.claude/agents/sql-quality-agent.md
@.claude/agents/code-review-agent.md
@videos/integrating_aws_s3_athena/CLAUDE.md
@videos/claude_code_overview/README.md
</context>

<requirements>
1. **Format**: Speaker script with embedded demo instructions - talking points AND step-by-step demo commands

2. **Session structure** (~40 minutes presentation, leaving 20 min for Q&A):
   - Foundation/context engineering concepts first (slides/discussion)
   - Then 1-2 fluid integrated demos (not isolated tool-by-tool demos)
   - Demo should use AWS/climate data (IMF Global Surface Temperature dataset at s3://kclabs-athena-demo-2026/climate-data/)

3. **Demo approach**:
   - All live demos, full terminal visible
   - Show how tools work together in realistic data analysis workflows
   - Highlight context engineering patterns (CLAUDE.md, commands, agents)

4. **Existing files to review and improve**:
   - `videos/az_emerging_tech_meetup/README.md` - Overview and checklist
   - `videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md` - Speaker script with timing
   - `videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md` - Copy-paste ready commands for live demos

5. **Improvement guidelines**:
   - Tighten language - remove filler and redundancy
   - Cut sections that don't directly support the core message
   - Ensure timing fits 40-minute constraint
   - Keep demo scripts focused on essential commands only
   - Prioritize impact over comprehensiveness
</requirements>

<implementation>
Structure the presentation as (~40 min content, 20 min Q&A):

**Section 1: Introduction (3 min)**
- Hook: "What if AI could handle your entire data workflow?"
- Quick overview of what we'll cover
- No lengthy agenda - get to content fast

**Section 2: Foundation - Context Engineering (10 min)**
- Repository structure (brief)
- CLAUDE.md key sections only (role, rules, tools)
- Custom commands - show don't tell
- Custom agents - brief mention, will see in action

**Section 3: Demo 1 - Starting a Data Request (12 min)**
- Use `/initiate-request` command
- Show Snowflake integration with TPC-H sample data
- Demonstrate automatic QC, folder structure
- Quick `/review-work` to show agents

**Section 4: Demo 2 - AWS Climate Analysis (12 min)**
- Use IMF climate data in S3
- S3 verification, Athena table creation, analysis
- Show the "AI handles the mechanics" pattern
- Export results

**Section 5: Wrap-up (3 min)**
- Three key takeaways (brief)
- Resources link
- Transition to Q&A

**Q&A (~20 min)**
- Open floor for questions

Keep pre-demo checklist but trim troubleshooting to essentials.
</implementation>

<output>
Review and tighten the following existing files:

1. `./videos/az_emerging_tech_meetup/README.md`
   - Update session structure to reflect 40-min presentation + 20-min Q&A
   - Keep checklist concise

2. `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md`
   - Reduce to ~40 minutes of content
   - Cut redundant talking points
   - Tighten demo narration
   - Remove verbose explanations
   - Keep essential Q&A prep only

3. `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md`
   - Keep only essential commands
   - Trim troubleshooting to critical items
   - Remove redundant examples
</output>

<verification>
Before declaring complete, verify:
- All three files updated in videos/az_emerging_tech_meetup/
- Presentation timing adds up to ~40 minutes (leaving 20 for Q&A)
- Content is tighter than before - no bloat added
- Demo scripts reference actual S3 bucket (kclabs-athena-demo-2026)
- Commands reference actual custom commands and agents in this repo
</verification>

<success_criteria>
- Presentation fits comfortably in 40 minutes
- Materials are more concise than original versions
- Speaker can deliver without rushing
- Demo scripts contain only essential commands
- Clear value proposition delivered efficiently
</success_criteria>
