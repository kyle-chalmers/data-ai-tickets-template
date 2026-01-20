<objective>
Update the foundation/intro section of the Arizona AI & Emerging Technology Meetup presentation to focus on the critical context engineering patterns in this repository.

The intro should clearly demonstrate:
1. The ticket folder structure and why it matters
2. CLAUDE.md as the "brain" - key sections only
3. Brief mention of custom commands (will see in action during demos)

This sets up the audience to understand WHY the demos work so well.
</objective>

<context>
Event: Arizona AI & Emerging Technology Meetup
Date: January 21, 2026
Speaker: Kyle Chalmers
Audience: ~123 technical data engineers

The presentation has been restructured to:
- Section 1: Introduction (3 min) - Hook only
- Section 2: Foundation (10 min) - THIS IS WHAT WE'RE UPDATING
- Section 3: Demo 1 (12 min) - Jira → S3 → Snowflake
- Section 4: Demo 2 (12 min) - Databricks job with Jira
- Section 5: Wrap-up (3 min)
- Q&A (20 min)

Review these files to understand the current structure:
@videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md
@videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md
@CLAUDE.md (the actual file that will be shown)
@.claude/commands/ (list contents to see available commands)
</context>

<requirements>
1. **Folder structure emphasis** - Show how `tickets/[user]/[TICKET-XXX]/` organization enables Claude to:
   - Know where to put deliverables
   - Create numbered files for review order
   - Separate QC from final work

2. **CLAUDE.md walkthrough** - Focus on 3 key sections only:
   - Role definition ("Senior Data Engineer...")
   - Permission hierarchy (what Claude can/cannot do without asking)
   - Available CLI tools (Snowflake, AWS, Jira, Databricks, GitHub)

3. **Commands mention** - Quick list of `/initiate-request`, `/save-work`, `/review-work` - don't explain in detail, say "you'll see these in action"

4. **Timing** - Must fit in 10 minutes total for this section
</requirements>

<implementation>
Update PRESENTATION_GUIDE.md Section 2 to:
- Start with "the key insight" (context engineering concept)
- Show terminal: `tree -L 2 .` to display structure
- Open CLAUDE.md and scroll through key sections (don't read entire file)
- Quick command list
- Transition: "Now let's see this in action with a real request"

Keep narration tight - audience is technical, don't over-explain.
</implementation>

<output>
Edit these files in `./videos/az_emerging_tech_meetup/`:
1. `PRESENTATION_GUIDE.md` - Update Section 2 (Foundation) only
2. `DEMO_SCRIPTS.md` - Add any terminal commands needed for foundation walkthrough

Do NOT change the overall presentation structure or other sections.
</output>

<verification>
Before completing, verify:
- Section 2 fits in ~10 minutes when read aloud
- Terminal commands are copy-paste ready
- CLAUDE.md references point to actual sections in the file
- Transition to Demo 1 is smooth
</verification>

<success_criteria>
- Foundation section clearly explains WHY context engineering matters
- Shows actual repo structure (not generic examples)
- References real CLAUDE.md sections
- Tight narration without filler
</success_criteria>
