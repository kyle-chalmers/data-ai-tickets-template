<objective>
Create Demo 1 materials for the Arizona AI & Emerging Technology Meetup presentation.

This demo showcases a complete data analysis workflow:
1. User describes a request → Claude creates a Jira ticket (KAN project)
2. Research and download a NEW climate dataset (different from IMF temperature data)
3. Upload to S3
4. Load into Snowflake
5. Analyze in Snowflake with SQL
6. Transition Jira ticket to Done

The demo should highlight Claude's reasoning capabilities and CLI tool integration.
</objective>

<context>
Event: Arizona AI & Emerging Technology Meetup, January 21, 2026
Jira: https://kclabs.atlassian.net/jira/software/projects/KAN/boards/1 (project key: KAN)

Existing data already used (DO NOT use):
- IMF Global Surface Temperature dataset at s3://kclabs-athena-demo-2026/climate-data/

AWS resources available:
- S3 bucket: kclabs-athena-demo-2026
- Athena results bucket: kclabs-athena-results-2026
- Region: us-west-2

Snowflake available via `snow` CLI

This demo should take ~12 minutes during the presentation.
</context>

<research>
Research and find a suitable climate dataset that is:
1. Publicly available (no authentication required)
2. CSV or easily parseable format
3. Different from temperature change data - consider:
   - CO2 emissions by country
   - Sea level rise
   - Extreme weather events
   - Renewable energy adoption
   - Glacier/ice sheet data
4. Has enough data for interesting analysis (multiple years, countries)
5. From a reputable source (NOAA, NASA, World Bank, UN, etc.)

Document the dataset choice with:
- Source URL
- License/attribution
- Data structure
- Why it's good for demo purposes
</research>

<requirements>
1. **Natural language prompts** - Create the exact prompts Kyle will type during the demo that show off Claude's reasoning:
   - Initial request prompt (conversational, describes what's needed)
   - Follow-up prompts for each stage if needed

2. **Jira integration** - Demo must:
   - Create a ticket in KAN project using `acli` CLI
   - Transition ticket to Done at the end
   - Show Claude's understanding of workflow tools

3. **Data pipeline** - Complete flow:
   - Download dataset to local
   - Upload to S3 (kclabs-athena-demo-2026)
   - Create Snowflake table (external or internal)
   - Run analytical queries
   - Export results

4. **Reasoning showcase** - Prompts should be conversational, not step-by-step commands, so Claude has to figure out the approach

5. **Backup commands** - Reference commands in case live demo needs manual fallback
</requirements>

<implementation>
Create these deliverables:

1. **Dataset documentation** - New file documenting the chosen dataset:
   - `./videos/az_emerging_tech_meetup/datasets/demo1_dataset.md`

2. **Demo prompts** - Update DEMO_SCRIPTS.md with:
   - Initial prompt: "I need to analyze [topic]. Create a Jira ticket for this work, find a good public dataset, get it into Snowflake, and show me the key insights."
   - Any follow-up prompts needed
   - Expected Claude behaviors to narrate

3. **Presentation guide** - Update PRESENTATION_GUIDE.md Demo 1 section with:
   - Narration talking points
   - Key moments to highlight
   - Timing breakdown

4. **Backup scripts** - Reference CLI commands for manual fallback
</implementation>

<output>
Create/update these files:
1. `./videos/az_emerging_tech_meetup/datasets/demo1_dataset.md` - Dataset documentation
2. `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md` - Update Demo 1 section
3. `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md` - Update Demo 1 section
4. `./videos/az_emerging_tech_meetup/README.md` - Update demo data sources section
</output>

<verification>
Before completing:
- Dataset is publicly downloadable (test the URL)
- Jira commands use KAN project key
- S3 bucket name is correct (kclabs-athena-demo-2026)
- Prompts are conversational, not robotic
- Demo fits in ~12 minutes
- Backup commands are tested/valid
</verification>

<success_criteria>
- Demo showcases Claude's reasoning (not just command execution)
- Complete Jira → S3 → Snowflake → Analysis workflow
- New dataset is different and interesting
- Prompts feel natural for a live demo
- Audience sees value of CLI tool integration
</success_criteria>
