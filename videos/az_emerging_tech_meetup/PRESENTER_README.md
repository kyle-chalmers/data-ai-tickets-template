# Presenter Quick Reference

**Event:** The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows
**Date:** Wednesday, January 21, 2026, 6:00 PM - 7:00 PM MST
**Venue:** 1951@SkySong, Room 151, Scottsdale, AZ

---

## Quick Links

| Resource | Link |
|----------|------|
| **Presentation Guide** | [PRESENTATION_GUIDE.md](./PRESENTATION_GUIDE.md) |
| **Demo Scripts** | [DEMO_SCRIPTS.md](./DEMO_SCRIPTS.md) |
| **Pre-Event Checklist** | [README.md](./README.md) |

---

## Session Timing

| Section | Duration | Cumulative |
|---------|----------|------------|
| Introduction | 3 min | 3 min |
| Foundation (Context Engineering) | 10 min | 13 min |
| Demo 1: Jira → S3 → Snowflake | 12 min | 25 min |
| Demo 2: Databricks Job | 12 min | 37 min |
| Wrap-up & Resources | 3 min | 40 min |
| **Q&A** | 20 min | 60 min |

---

## Demo Prompts (Copy-Paste)

### Demo 1: CO2 Analysis
```
I need help with a data analysis project. Here's what I'm thinking:

We should analyze global CO2 emissions to understand which countries are the biggest emitters and how that's changed over time. I found a dataset from Our World in Data that has emissions by country from 1750 to 2024.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Download the data from https://owid-public.owid.io/data/co2/owid-co2-data.csv
3. Upload it to our S3 bucket at kclabs-athena-demo-2026
4. Load it into Snowflake so we can query it
5. Find the top 10 emitting countries in 2024
6. Show how US emissions have changed since 2000

Once we have results, mark the ticket as done.
```

### Demo 2: Databricks Job
```
I need to set up automated data collection for Arizona weather data. Here's what I'm thinking:

We should create a Databricks job that runs monthly to pull fresh weather data from the Open-Meteo API. I want to track temperature, precipitation, and wind patterns for major Arizona cities - Phoenix, Tucson, Flagstaff, and a few others.

Can you help me:
1. Create a Jira ticket to track this work (use KAN project)
2. Research the Open-Meteo API to understand what data we can get
3. Write a Python script that fetches monthly weather data
4. Create a Databricks job configuration that runs on the 3rd of each month
5. Deploy the job to our development environment (use the bidev profile)
6. Test it with a manual run

Add a comment to the ticket when the job is deployed, then mark it done when everything is working.
```

---

## End of Presentation - Resources

### Connect With Me

| Platform | Link | QR Code |
|----------|------|---------|
| **LinkedIn** | [linkedin.com/in/kylechalmers](https://www.linkedin.com/in/kylechalmers/) | ![LinkedIn QR](./qr_codes/linkedin_qr.png) |
| **YouTube** | [KC Labs AI Channel](https://www.youtube.com/channel/UCkRi29nXFxNBuPhjseoB6AQ) | ![YouTube QR](./qr_codes/youtube_qr.png) |
| **GitHub Repo** | [data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) | ![Repo QR](./qr_codes/repo_qr.png) |

### Getting Started

- **Claude Code**: [claude.ai/download](https://claude.ai/download)
- **This Repository**: [github.com/kyle-chalmers/data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template)

---

## Pre-Demo Verification (30 min before)

```bash
# Navigate to repo
cd /Users/kylechalmers/Development/data-ai-tickets-template
git checkout main && git pull

# Test connections
snow sql -q "SELECT 1" --format csv
aws sts get-caller-identity
acli jira project list --filter KAN
databricks workspace list / --profile bidev

# Start Claude Code
claude
/clear
```

---

## Backup Plans

| Issue | Action |
|-------|--------|
| Snowflake fails | Use pre-run CSV results |
| AWS timeout | Show S3 console, manual upload |
| Databricks fails | Walk through code, explain deployment |
| Jira fails | Skip ticket creation, focus on data pipeline |
| Claude unresponsive | `/clear` and retry, or show pre-recorded |

---

## Closing Script

> "Thank you for being here tonight. If you found this helpful, I'd love to connect."
>
> **[Show QR codes on screen]**
>
> "Here are the QR codes - LinkedIn if you want to connect professionally, YouTube for more detailed tutorials on each integration, and the GitHub repo where all of this code lives."
>
> "I'll be around after for anyone who wants to chat about implementations or see anything in more detail."
>
> "Thanks to Arizona AI & Emerging Technology Meetup for having me!"

---

## Terminal Setup

- Font size: **18-20pt**
- Theme: Dark background with high contrast
- Notifications: **OFF**
- Second monitor: This README open for reference
