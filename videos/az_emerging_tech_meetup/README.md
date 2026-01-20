# Arizona AI & Emerging Technology Meetup Presentation

**Event:** The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows
**Date:** Wednesday, January 21, 2026, 6:00 PM - 7:00 PM MST
**Venue:** 1951@SkySong, 1475 N. Scottsdale Road, Room 151, Scottsdale, AZ
**Meetup Link:** https://www.meetup.com/azemergingtech/events/312526569/

---

## Contents

| File | Description |
|------|-------------|
| [PRESENTER_README.md](./PRESENTER_README.md) | **Primary presenter reference** - Quick links, prompts, QR codes |
| [PRESENTATION_GUIDE.md](./PRESENTATION_GUIDE.md) | Full speaker script with timing and narration |
| [DEMO_SCRIPTS.md](./DEMO_SCRIPTS.md) | Copy-paste commands for live demos |
| [datasets/demo1_dataset.md](./datasets/demo1_dataset.md) | CO2 emissions dataset documentation |
| [qr_codes/](./qr_codes/) | QR codes for LinkedIn, YouTube, GitHub repo |

**Related Files:**
| File | Description |
|------|-------------|
| [databricks_jobs/](../../databricks_jobs/) | Databricks job files for Demo 2 |
| [databricks_jobs/climate_data_refresh/](../../databricks_jobs/climate_data_refresh/) | Monthly climate refresh job |

---

## Session Structure (~40 min presentation + 20 min Q&A)

| Section | Time | Content |
|---------|------|---------|
| Introduction | 3 min | Hook, what we'll cover |
| Foundation: Context Engineering | 10 min | CLAUDE.md key sections, commands, agents |
| Demo 1: Complete Data Pipeline | 12 min | Jira -> S3 -> Snowflake (CO2 emissions) |
| Demo 2: Databricks Infrastructure | 12 min | Jira -> Research -> Deploy job (Arizona weather) |
| Wrap-up | 3 min | Three takeaways, resources |
| **Q&A** | **20 min** | Open questions |

**Total Presentation Time:** ~40 minutes

---

## Key Tools Demonstrated

1. **Claude Code** - AI-powered CLI assistant
2. **Snowflake CLI (`snow`)** - Data warehouse queries
3. **AWS CLI (`aws`)** - S3 operations
4. **Databricks CLI (`databricks`)** - Job deployment (profile: `bidev`)
5. **Jira CLI (`acli`)** - Ticket tracking (project: `KAN`)
6. **Custom Commands** - `/initiate-request`, `/save-work`, `/review-work`
7. **Custom Agents** - code-review, sql-quality, qc-validator

---

## Demo Data Sources

### Demo 1: CO2 Emissions (Jira -> S3 -> Snowflake)

| Property | Value |
|----------|-------|
| **Dataset** | Our World in Data CO2 and Greenhouse Gas Emissions |
| **Source URL** | https://owid-public.owid.io/data/co2/owid-co2-data.csv |
| **Rows** | ~50,000 |
| **Countries** | 255 |
| **Year Range** | 1750-2024 |
| **License** | Creative Commons BY 4.0 |
| **S3 Target** | `s3://kclabs-athena-demo-2026/co2-emissions/` |
| **Snowflake Table** | `DEMO_DATA.PUBLIC.CO2_EMISSIONS` |

**Key Columns:** country, year, iso_code, co2, co2_per_capita, coal_co2, oil_co2, gas_co2, share_global_co2

**Demo Flow:** Conversational prompt -> Jira ticket -> Download CSV -> S3 upload -> Snowflake table -> Analysis queries -> Close ticket

---

### Demo 2: Arizona Weather (Jira -> Research -> Databricks Job)

| Property | Value |
|----------|-------|
| **Data Source** | Open-Meteo Historical Weather API |
| **API URL** | `https://archive-api.open-meteo.com/v1/archive` |
| **Authentication** | None required (free) |
| **Cities** | 10 Arizona cities (Phoenix, Tucson, Flagstaff, etc.) |
| **Schedule** | Monthly on 3rd day, 6 AM |
| **Databricks Profile** | `bidev` |
| **Output Table** | `climate_demo.monthly_arizona_weather` |

**Demo Flow:** Conversational prompt -> Jira ticket -> API research -> Python job creation -> Deploy to Databricks -> Test run -> Close ticket

**Key Difference from Demo 1:** Shows infrastructure/automation building, not just data analysis

---

## Pre-Event Checklist

### Day Before
- [ ] Test Snowflake: `snow sql -q "SELECT 1" --format csv`
- [ ] Test AWS: `aws sts get-caller-identity`
- [ ] Verify S3 bucket: `aws s3 ls s3://kclabs-athena-demo-2026/`
- [ ] Test Jira: `acli jira project list --filter KAN`
- [ ] Test Databricks: `databricks workspace list / --profile bidev`
- [ ] Test Open-Meteo API: `curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-05&daily=temperature_2m_max"`
- [ ] Clean up test branches: `git branch -d [demo-branches]`
- [ ] Review PRESENTATION_GUIDE.md timing

### 30 Minutes Before
- [ ] `cd /Users/kylechalmers/Development/data-ai-tickets-template`
- [ ] `git checkout main && git pull`
- [ ] Start Claude Code, run `/clear`
- [ ] Increase terminal font to 18-20pt
- [ ] Disable notifications
- [ ] Have DEMO_SCRIPTS.md open in separate window

---

## Jira Integration

**Project:** KAN (kclabs.atlassian.net)
**Board:** https://kclabs.atlassian.net/jira/software/projects/KAN/boards/1
**CLI Tool:** `acli` (Atlassian CLI)

**Both demos create a Jira ticket, perform the work, then close it - showing full workflow automation.**

---

## Backup Plans

| Issue | Fallback |
|-------|----------|
| Jira fails | Skip ticket creation, show data pipeline only |
| Snowflake connection | Demo 1 can work with S3 + local analysis |
| Databricks connection | Show job code walkthrough, explain deployment steps |
| Open-Meteo API down | Use pre-cached test data or skip to job structure |
| AWS timeout | Have pre-run results CSV ready |
| Claude not responding | Walk through concepts with code samples from DEMO_SCRIPTS.md |

**Recovery Steps:**
1. If Demo 1 fails mid-way, switch to Demo 2
2. If Demo 2 fails mid-way, switch to Q&A with conceptual discussion
3. If both demos fail, walk through DEMO_SCRIPTS.md backup commands manually

---

## Resources

### Connect With Kyle
| Platform | Link | QR Code |
|----------|------|---------|
| **LinkedIn** | [linkedin.com/in/kylechalmers](https://www.linkedin.com/in/kylechalmers/) | [qr_codes/linkedin_qr.png](./qr_codes/linkedin_qr.png) |
| **YouTube** | [KC Labs AI Channel](https://www.youtube.com/channel/UCkRi29nXFxNBuPhjseoB6AQ) | [qr_codes/youtube_qr.png](./qr_codes/youtube_qr.png) |
| **GitHub Repo** | [data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) | [qr_codes/repo_qr.png](./qr_codes/repo_qr.png) |

### Technical Resources
- **Claude Code**: claude.ai/download
- **Our World in Data**: github.com/owid/co2-data
- **Open-Meteo API**: open-meteo.com/en/docs/historical-weather-api
- **Databricks CLI**: docs.databricks.com/dev-tools/cli/
