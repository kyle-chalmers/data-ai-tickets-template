<objective>
Reformat the AWS S3 + Athena integration script from technical documentation style to video-production style.

The current script reads like technical docs with code blocks. It needs to become a video script with timing cues, speaking lines, visual directions, and a conversational flow.
</objective>

<context>
**Source script to reformat:**
`./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md`

**Reference script to match style:**
`/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/7 Data Career Evolution.docx`

Use `pandoc -t plain [file.docx]` to read the reference script.

**Key style elements from reference:**
- Time estimates in section headers (e.g., "HOOK INTRO (90-120 seconds)")
- Moment-by-moment breakdown (e.g., "First 5 Seconds", "6-10 Seconds")
- Direct speaking lines in quotes
- Visual/screen cues in brackets [like this]
- Personal anecdote opportunity markers
- Section transitions that tease next content
- Bullet points for talking points, not technical specs
- Definitions box for technical terms viewers may not know
</context>

<requirements>
1. **Read both files** - the source script and the reference script
2. **Preserve all content** from the AWS script - don't lose any information
3. **Transform the structure** to match the reference style:
   - Add time estimates to each section
   - Convert bullet points to speaking lines where appropriate
   - Add [visual cues] for screen recordings/demos
   - Mark [personal anecdote opportunity] spots
   - Add section transitions
4. **Keep code blocks** but frame them as "show on screen" moments
5. **Add a definitions section** for terms like: S3, Athena, data lake, CLI, IAM, external table
</requirements>

<output>
Save the reformatted script to:
- `./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md` (overwrite)
- `/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/AWS S3 Athena Integration Script Outline.md` (overwrite)

Both files should be identical.
</output>

<verification>
Before completing, verify:
- All original content preserved (demo workflow, queries, talking points)
- Time estimates added to all major sections
- Visual cues added for screen recording moments
- Speaking lines are conversational, not technical
- Structure matches the Data Career Evolution script style
</verification>
</content>
</invoke>