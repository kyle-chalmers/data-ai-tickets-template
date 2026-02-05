<objective>
Create a short video intro script for a YouTube video that introduces Kyle's recorded meetup presentation at the Arizona AI & Emerging Tech Meetup. This intro will be filmed separately and edited before the recorded presentation footage.

The intro should:
- Hook viewers and explain what they're about to watch
- Provide context about the meetup event
- Set expectations that this is a recorded live presentation
- Be brief (60-90 seconds when spoken) since the full content is already recorded
</objective>

<context>
**Event Details:**
- Event: "The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows"
- Date: Wednesday, January 21, 2026
- Location: 1951@SkySong, Scottsdale, AZ (Arizona AI & Emerging Technology Meetup)
- Audience: 123 attendees
- Speaker: Kyle Chalmers

**Presentation Content:**
The presentation demonstrates integrating Claude Code with data tools (Snowflake, Jira, Databricks, GitHub) for 10x productivity gains. It covers:
- Context engineering fundamentals (CLAUDE.md, folder structure, custom commands)
- Demo 1: Complete data pipeline (Jira → S3 → Snowflake) analyzing global CO2 emissions
- Demo 2: Databricks infrastructure (Jira → Research → Databricks Job) for Arizona weather data collection

**Key Takeaways from the Presentation:**
1. Context is everything - Claude Code is only as good as the context you give it
2. Productivity for data work explodes with proper AI setup
3. More thinking, less typing - AI handles execution, humans handle oversight

**Source Materials:**
@/Users/kylechalmers/Development/data-ai-tickets-template/videos/az_emerging_tech_meetup/README.md

**KC Labs AI Channel Style:**
- Professional but conversational tone
- Evidence-based, practical, approachable
- Target audience: Data analysts and BI professionals
- Lead with value, not credentials
</context>

<requirements>
Create an intro script in VIDEO PRODUCTION FORMAT that includes:

1. **Hook (First 5 seconds)** - High energy opening that grabs attention
   - Direct speaking line in quotes
   - Why viewers should care about this recording

2. **Context Setting (10-15 seconds)** - Explain what this video is
   - Mention it's a recorded live presentation
   - Name the event and location
   - Brief credibility note (audience size, venue)

3. **Preview (15-20 seconds)** - What viewers will see
   - Brief overview of the two demos
   - The promise/value they'll get from watching

4. **Transition to Recording (5-10 seconds)** - Hand off to the presentation
   - Set expectations for live presentation format
   - Any viewing notes (audio quality, Q&A trimmed, etc.)

**Format Requirements:**
- Use video production format with timing cues
- Include direct speaking lines in quotes for key moments
- Include [visual cues] in brackets where relevant
- Keep total runtime 60-90 seconds when spoken
- DO NOT include full presentation content - this is INTRO ONLY
</requirements>

<output>
Save the script to Google Drive following the /yt-script workflow:

1. Check existing files in Scripts folder: `/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/`
2. Determine next file number
3. Create Word document using python-docx
4. Save as: `{number} AZ Emerging Tech Meetup Intro.docx`

The intro script should be ready for Kyle to record as a standalone piece that will be edited before the meetup footage.
</output>

<verification>
Before completing:
- [ ] Script is 60-90 seconds when read aloud (approximately 150-225 words)
- [ ] Includes direct speaking lines in quotes
- [ ] Has clear timing breakdown
- [ ] Follows video production format (not technical documentation)
- [ ] Saved to correct Google Drive location with correct naming
</verification>

<success_criteria>
- A concise, engaging intro script that makes viewers want to watch the full meetup recording
- Properly formatted for video production with timing cues
- Saved to Google Drive Scripts folder with sequential numbering
</success_criteria>
