<objective>
Finalize all presentation materials after Demo 1 and Demo 2 content has been created.

This prompt consolidates all changes, ensures consistency across files, and prepares materials for the live presentation.
</objective>

<context>
Event: Arizona AI & Emerging Technology Meetup, January 21, 2026
Speaker: Kyle Chalmers

Previous prompts have created:
- Updated foundation materials (prompt 002)
- Demo 1: Climate data Jira → S3 → Snowflake workflow (prompt 003)
- Demo 2: Databricks monthly job with Jira (prompt 004)

Review all created materials:
@videos/az_emerging_tech_meetup/
@databricks_jobs/
</context>

<requirements>
1. **Consistency check** - Ensure all files reference:
   - Same Jira project (KAN)
   - Same S3 bucket (kclabs-athena-demo-2026)
   - Same Databricks profile (bidev)
   - Consistent timing (40 min presentation + 20 min Q&A)

2. **README update** - Update main README with:
   - Accurate session structure
   - All demo data sources documented
   - Updated pre-event checklist
   - Correct file references

3. **Presentation flow** - Verify PRESENTATION_GUIDE.md has:
   - Smooth transitions between sections
   - Consistent narration style
   - No redundant content
   - Total timing adds to ~40 minutes

4. **Demo scripts** - Verify DEMO_SCRIPTS.md has:
   - All prompts ready to copy-paste
   - Backup commands organized clearly
   - Troubleshooting section updated

5. **Pre-event checklist** - Update with:
   - New dataset verification commands
   - Databricks job verification
   - Jira access check
</requirements>

<implementation>
1. Read all presentation files
2. Check for inconsistencies
3. Update README.md with final structure
4. Ensure smooth transitions in PRESENTATION_GUIDE.md
5. Organize DEMO_SCRIPTS.md for easy reference during live demo
6. Test all verification commands
</implementation>

<output>
Update these files:
1. `./videos/az_emerging_tech_meetup/README.md` - Final overview
2. `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md` - Final polish
3. `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md` - Final organization
</output>

<verification>
Before completing:
- All timings add up to ~40 minutes
- No broken file references
- All CLI commands are correct
- Pre-event checklist is complete
- Materials are ready for live presentation
</verification>

<success_criteria>
- All materials are consistent
- Presentation flows naturally
- Speaker can deliver without confusion
- Backup plans are documented
- Ready for January 21, 2026 event
</success_criteria>
