<objective>
Create Demo 2 materials for the Arizona AI & Emerging Technology Meetup presentation.

This demo showcases building a scheduled data pipeline:
1. User describes a request → Claude creates a Jira ticket (KAN project)
2. Research an external climate data API or source
3. Create a Databricks job that pulls fresh data monthly
4. Test the job
5. Transition Jira ticket to Done with a comment

The demo shows Claude can handle infrastructure/ETL tasks, not just analysis.
</objective>

<context>
Event: Arizona AI & Emerging Technology Meetup, January 21, 2026
Jira: https://kclabs.atlassian.net/jira/software/projects/KAN/boards/1 (project key: KAN)

Databricks CLI available with profiles:
- `biprod` (production)
- `bidev` (development) - USE THIS FOR DEMO

This demo should take ~12 minutes during the presentation.

Create a new folder `databricks_jobs_cursor/` in the repository to store the job code.
</context>

<research>
Research and identify a suitable external climate data source that:
1. Has an API or scheduled download capability
2. Updates regularly (monthly or more frequent)
3. Is freely accessible
4. Good candidates:
   - NOAA Climate Data API
   - NASA Earth Data
   - Open-Meteo API
   - World Bank Climate API
   - Carbon Intensity API

Document the chosen source with:
- API/endpoint details
- Authentication requirements (prefer none)
- Update frequency
- Data format
</research>

<requirements>
1. **Natural language prompts** - Create conversational prompts that:
   - Describe the business need (monthly climate data refresh)
   - Let Claude figure out the implementation
   - Show reasoning about job scheduling, error handling, etc.

2. **Jira workflow** - Demo must:
   - Create ticket in KAN project using `acli` CLI
   - Add a comment when job is created
   - Transition to Done when complete

3. **Databricks job** - Create actual job code:
   - Python script to fetch external data
   - Job configuration (schedule, cluster settings)
   - Error handling
   - Store in `databricks_jobs_cursor/` folder

4. **Job testing** - Show how to:
   - Deploy job to Databricks (bidev profile)
   - Trigger manual run
   - Check job status

5. **Reasoning showcase** - Claude should demonstrate thinking about:
   - What schedule makes sense
   - How to handle API failures
   - Where to store data
   - How to validate data quality
</requirements>

<implementation>
Create these deliverables:

1. **Databricks job folder**:
   ```
   databricks_jobs_cursor/
   ├── README.md                    # Overview of jobs in this folder
   └── climate_data_refresh/
       ├── climate_refresh.py       # Main job script
       ├── job_config.json          # Databricks job configuration
       └── README.md                # Job-specific documentation
   ```

2. **Demo prompts** - Update DEMO_SCRIPTS.md with:
   - Initial prompt describing the monthly refresh need
   - Follow-up prompts if needed
   - Expected behaviors to narrate

3. **Presentation guide** - Update PRESENTATION_GUIDE.md Demo 2 section with:
   - Narration talking points
   - Key moments (job creation, testing, Jira updates)
   - Timing breakdown

4. **Backup commands** - Databricks CLI commands for manual fallback
</requirements>

<output>
Create/update these files:
1. `./databricks_jobs_cursor/README.md` - Jobs folder overview
2. `./databricks_jobs_cursor/climate_data_refresh/climate_refresh.py` - Job script
3. `./databricks_jobs_cursor/climate_data_refresh/job_config.json` - Job config
4. `./databricks_jobs_cursor/climate_data_refresh/README.md` - Job documentation
5. `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md` - Update Demo 2 section
6. `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md` - Update Demo 2 section
</output>

<verification>
Before completing:
- Job script is syntactically valid Python
- Job config is valid JSON for Databricks
- External API/source is accessible (test it)
- Jira commands use KAN project key
- Databricks commands use bidev profile
- Demo fits in ~12 minutes
</verification>

<success_criteria>
- Demo shows Claude handling ETL/infrastructure tasks
- Complete Jira → Code → Deploy → Test → Close workflow
- Actual working job code (not placeholder)
- Shows scheduling and error handling thinking
- Different from Demo 1 (analysis vs pipeline)
</success_criteria>
