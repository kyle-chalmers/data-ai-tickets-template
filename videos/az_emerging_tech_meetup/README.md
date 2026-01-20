# Arizona AI & Emerging Technology Meetup Presentation

**Event:** The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows
**Date:** Wednesday, January 21, 2026, 6:00 PM - 7:00 PM MST
**Venue:** 1951@SkySong, 1475 N. Scottsdale Road, Room 151, Scottsdale, AZ
**Meetup Link:** https://www.meetup.com/azemergingtech/events/312526569/

---

## Contents

- [PRESENTATION_GUIDE.md](./PRESENTATION_GUIDE.md) - Speaker script with timing and demo narration
- [DEMO_SCRIPTS.md](./DEMO_SCRIPTS.md) - Copy-paste commands for live demos

---

## Session Structure (~40 min presentation + 20 min Q&A)

| Section | Time | Content |
|---------|------|---------|
| Introduction | 3 min | Hook, what we'll cover |
| Foundation: Context Engineering | 10 min | CLAUDE.md key sections, commands, agents |
| Demo 1: Starting a Data Request | 12 min | `/initiate-request` + Snowflake TPC-H |
| Demo 2: AWS Climate Analysis | 12 min | S3 + Athena end-to-end |
| Wrap-up | 3 min | Three takeaways, resources |
| **Q&A** | **20 min** | Open questions |

---

## Key Tools Demonstrated

1. **Claude Code** - AI-powered CLI assistant
2. **Snowflake CLI (`snow`)** - Data warehouse queries
3. **AWS CLI (`aws`)** - S3 and Athena operations
4. **Custom Commands** - `/initiate-request`, `/save-work`, `/review-work`
5. **Custom Agents** - code-review, sql-quality, qc-validator

---

## Pre-Event Checklist

### Day Before
- [ ] Test Snowflake: `snow sql -q "SELECT 1" --format csv`
- [ ] Test AWS: `aws sts get-caller-identity`
- [ ] Verify S3 data: `aws s3 ls s3://kclabs-athena-demo-2026/climate-data/`
- [ ] Clean up test branches: `git branch -d [demo-branches]`

### 30 Minutes Before
- [ ] `cd /Users/kylechalmers/Development/data-ai-tickets-template`
- [ ] `git checkout main && git pull`
- [ ] Start Claude Code, run `/clear`
- [ ] Increase terminal font to 18-20pt
- [ ] Disable notifications

---

## Demo Data Sources

**Demo 1:** Snowflake Sample Data (TPC-H)
- Database: `snowflake_sample_data.tpch_sf1`
- Tables: `customer`, `orders`, `nation`

**Demo 2:** IMF Global Surface Temperature Dataset
- S3: `s3://kclabs-athena-demo-2026/climate-data/`
- Athena Database: `climate_demo`
- Table: `global_temperature`
- Coverage: 1961-2024, 200+ countries
