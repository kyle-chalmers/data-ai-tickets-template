<objective>
Examine all YouTube content production skills and update them to produce scripts in the video-production style (with timing, speaking lines, visual cues) rather than technical documentation style.
</objective>

<context>
**Skills to examine:**
1. `youtube-content-production` - Main orchestration skill
2. `yt-script` - Script writing skill
3. `generate-script-outline` - Script outline generation skill

**Reference script style:**
`/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/7 Data Career Evolution.docx`

Use `pandoc -t plain [file.docx]` to read reference.

**Target output style characteristics:**
- Time estimates in section headers (e.g., "SECTION 1: Title (3-4 minutes)")
- Moment-by-moment breakdown for intro (First 5 seconds, 6-10 seconds, etc.)
- Direct speaking lines in quotes for key moments
- Visual/screen cues in [brackets]
- [Personal anecdote opportunity] markers
- Section transitions that preview next content
- Definitions section for technical terms
- Conversational bullet points, not technical specs
</context>

<tasks>
1. **Find and read all three skills** - Search in `.claude/` directory for skill files
2. **Analyze each skill** - Determine what output format they currently produce
3. **Identify the primary skill** that controls script output format
4. **Update the skill(s)** to include:
   - Instructions to use video-production format
   - Reference to the style guide characteristics listed above
   - Example structure showing timing, speaking lines, visual cues
5. **Ensure consistency** - All skills should produce compatible output
</tasks>

<output>
For each skill examined, report:
- File location
- Current purpose
- Changes made (or "no changes needed")

Update skill files in place.
</output>

<verification>
Before completing:
- All three skills located and examined
- Primary script-generating skill identified and updated
- Style guide incorporated into skill instructions
- Skills will now produce video-production format scripts
</verification>
</content>
