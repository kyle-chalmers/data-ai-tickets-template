<objective>
Consolidate the presentation materials in `/Users/kylechalmers/Development/data-ai-tickets-template/videos/az_emerging_tech_meetup/` from 4 redundant markdown files into 2 well-designed documents:
1. **README.md** - Audience-facing screen share with visually appealing design
2. **PRESENTATION_GUIDE.md** - Presenter-only guide with timing and talking points

Delete the redundant files after consolidation: DEMO_SCRIPTS.md and PRESENTER_README.md
</objective>

<context>
**Event Details:**
- Event: Arizona AI & Emerging Technology Meetup
- Title: The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows
- Date: Wednesday, January 21, 2026, 6:00 PM - 7:00 PM MST
- Venue: 1951@SkySong, 1475 N. Scottsdale Road, Room 151, Scottsdale, AZ
- Meetup Link: https://www.meetup.com/azemergingtech/events/312526569/
- Format: ~40 min presentation + 20 min Q&A

**Current Files (all have redundant content):**
- README.md - General overview
- DEMO_SCRIPTS.md - Copy-paste commands and prompts
- PRESENTER_README.md - Quick reference for presenter
- PRESENTATION_GUIDE.md - Full speaker script with narration

**Key Content That Appears in Multiple Places:**
- Demo prompts (appear 3 times)
- Session timing (appears 4 times)
- Pre-demo checklist (appears 3 times)
- Resources/QR codes (appears 3 times)
- Backup plans (appears 3 times)

**Source Files to Read:**
@videos/az_emerging_tech_meetup/README.md
@videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md
@videos/az_emerging_tech_meetup/PRESENTER_README.md
@videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md
@videos/az_emerging_tech_meetup/datasets/demo1_dataset.md
</context>

<requirements>

## README.md Requirements (Audience-Facing Screen Share)

This file will be displayed on screen during the presentation. Design it to be visually appealing and professional.

### Structure:
1. **Header Section** - Event title and presenter info with professional styling
2. **QR Codes & Resources (TOP)** - Display prominently at the very top so audience can scan immediately
3. **Visual Session Overview** - Styled agenda/flow diagram
4. **Demo 1: Complete Data Pipeline** - Include the full prompt for audience to follow
5. **Demo 2: Databricks Infrastructure** - Include the full prompt for audience to follow
6. **Key Tools & Technologies** - Visual representation
7. **Three Takeaways** - Memorable summary points
8. **QR Codes & Resources (BOTTOM)** - Repeat at the end for late scanners

### Design Elements to Include:
- Use horizontal rules (`---`) to separate sections
- Use tables for structured information
- Use blockquotes (`>`) for key takeaways or emphasis
- Consider ASCII art or simple diagrams for visual flow
- Use emoji sparingly for visual markers (📊 🔧 🚀)
- Create visual "cards" using tables with single cells for important items
- Use code blocks with syntax highlighting for the demo prompts
- Include the QR code image references from `./qr_codes/` folder

### Content for README.md:
- Event details (title, date, venue)
- QR codes for LinkedIn, YouTube, GitHub repo (both top and bottom)
- Session overview with visual flow
- Both demo prompts (full text, copy-pasteable)
- Key tools list with brief descriptions
- Three takeaways
- Links to getting started resources

**IMPORTANT:** Do NOT include:
- Presenter notes or talking points
- Timing information
- Pre-demo verification commands
- Backup plans
- Terminal setup instructions
- Troubleshooting guides

## PRESENTATION_GUIDE.md Requirements (Presenter-Only)

This file is for Kyle's eyes only during presentation. Focus on timing, talking points, and operational details.

### Structure:
1. **Quick Reference Card** - At-a-glance timing and key commands
2. **Pre-Demo Checklist** - Day before and 30 minutes before
3. **Terminal Setup** - Font size, theme, notifications
4. **Full Speaker Script** - Section by section with:
   - Timing for each section
   - What to say (narration)
   - What to do (commands/actions)
   - Key points to emphasize
5. **Demo Narration Points** - What to say while Claude works
6. **Backup Plans** - What to do if things fail
7. **Troubleshooting Quick Reference**
8. **Closing Script** - Exact words for wrap-up
9. **Post-Presentation Cleanup**

### Content Sources:
- Pull timing from current PRESENTATION_GUIDE.md
- Pull narration and talking points from current PRESENTATION_GUIDE.md
- Pull pre-demo verification from DEMO_SCRIPTS.md
- Pull backup commands from DEMO_SCRIPTS.md
- Pull troubleshooting from DEMO_SCRIPTS.md
- Pull closing script from PRESENTER_README.md

**IMPORTANT:** Do NOT include:
- Demo prompts (those are in README.md for screen share)
- Full QR codes section (audience-facing content)
- Detailed dataset documentation

</requirements>

<implementation>

### Step 1: Create the new README.md
1. Read all source files to extract relevant content
2. Design visually appealing structure with diagrams
3. Place QR codes prominently at TOP
4. Include both full demo prompts in styled code blocks
5. Add visual flow diagram for session structure
6. Repeat QR codes at BOTTOM
7. Write to `./videos/az_emerging_tech_meetup/README.md`

### Step 2: Create the new PRESENTATION_GUIDE.md
1. Extract timing information from existing PRESENTATION_GUIDE.md
2. Consolidate all pre-demo checklists
3. Include full speaker narration
4. Add backup plans and troubleshooting
5. Include terminal commands for verification
6. Write to `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md`

### Step 3: Delete redundant files
1. Delete `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md`
2. Delete `./videos/az_emerging_tech_meetup/PRESENTER_README.md`

### Step 4: Verify
1. Confirm README.md contains both demo prompts
2. Confirm PRESENTATION_GUIDE.md has all timing and narration
3. Confirm deleted files are gone
4. List remaining files to verify clean structure

</implementation>

<design_examples>

### Example: Visual Session Flow Diagram
```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SESSION FLOW (60 min)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐ │
│   │   Intro  │───▶│  Foundation  │───▶│   Demo 1    │───▶│  Demo 2  │ │
│   │  (3 min) │    │   (10 min)   │    │  (12 min)   │    │ (12 min) │ │
│   └──────────┘    └──────────────┘    └─────────────┘    └──────────┘ │
│                                                                    │    │
│        ┌──────────────────────────────────────────────────────────┘    │
│        │                                                                │
│        ▼                                                                │
│   ┌──────────┐    ┌──────────────────────────────────────────────────┐ │
│   │ Wrap-up  │───▶│                    Q&A (20 min)                  │ │
│   │  (3 min) │    └──────────────────────────────────────────────────┘ │
│   └──────────┘                                                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Example: Resource Card Design
```markdown
| 🔗 **Connect** | 📺 **Watch** | 💻 **Code** |
|:---:|:---:|:---:|
| [![LinkedIn](./qr_codes/linkedin_qr.png)](https://linkedin.com/in/kylechalmers) | [![YouTube](./qr_codes/youtube_qr.png)](https://youtube.com/@kclabsai) | [![GitHub](./qr_codes/repo_qr.png)](https://github.com/kyle-chalmers/data-ai-tickets-template) |
| **LinkedIn** | **YouTube** | **GitHub Repo** |
```

### Example: Demo Flow Visualization
```
DEMO 1: Complete Data Pipeline
────────────────────────────────────────────────────
    📝 Jira          📥 Download       ☁️ S3
   Ticket    ───▶     CSV      ───▶   Upload
                                         │
                                         ▼
    ✅ Close         📊 Analyze       ❄️ Snowflake
    Ticket   ◀───    Results   ◀───   Load
────────────────────────────────────────────────────
```

</design_examples>

<output>
Create/modify files with relative paths:
- `./videos/az_emerging_tech_meetup/README.md` - Audience-facing, visually designed
- `./videos/az_emerging_tech_meetup/PRESENTATION_GUIDE.md` - Presenter-only guide

Delete these files:
- `./videos/az_emerging_tech_meetup/DEMO_SCRIPTS.md`
- `./videos/az_emerging_tech_meetup/PRESENTER_README.md`
</output>

<verification>
Before declaring complete, verify:
1. README.md has QR codes at BOTH top and bottom
2. README.md contains BOTH full demo prompts
3. README.md has NO presenter-only content (timing, narration, backup plans)
4. PRESENTATION_GUIDE.md has complete timing for all sections
5. PRESENTATION_GUIDE.md has pre-demo verification commands
6. PRESENTATION_GUIDE.md has backup plans and troubleshooting
7. DEMO_SCRIPTS.md and PRESENTER_README.md are deleted
8. `ls videos/az_emerging_tech_meetup/` shows only: README.md, PRESENTATION_GUIDE.md, datasets/, qr_codes/
</verification>

<video_log_section>
At the very end of README.md (after the bottom QR codes section), include a "Video Log" section showcasing Kyle's previous videos. This provides context that the presentation is part of a larger body of work.

**Video Log Content:**

| Video Title | Description | Link |
|-------------|-------------|------|
| **FUTURE PROOF Your Data Career with this Claude Code Deep Dive** | Complete guide to Claude Code for data teams - installation, CLAUDE.md, commands, agents | [Watch](https://www.youtube.com/watch?v=g4g4yBcBNuE) |
| **UPDATE to settings.json Chapter** | Settings.json updates from the Claude Code Deep Dive | [Watch](https://youtu.be/WKt28ytMl3c) |
| **The AI Integration Every Data Professional Needs (Snowflake Workflow)** | Using Claude Code with Snowflake for data analysis | [Watch](https://www.youtube.com/watch?v=q1y7M5mZkkE) |
| **Claude Code Makes Databricks Easy** | Jobs, notebooks, SQL & Unity Catalog via CLI | [Watch](https://www.youtube.com/watch?v=5_q7j-k8DbM) |
| **How to SUCCESSFULLY Integrate Claude in Your Team's Jira Ticket Workflow** | Jira/Confluence integration guide | [Watch](https://www.youtube.com/watch?v=WRvgMzYaIVo) |
| **Skip S3 and Athena in the AWS Console** | CLI + Claude Code Workflow for AWS data lakes | [Watch](https://www.youtube.com/watch?v=kCUTStWwErg) |
| **Stop Waiting: Use AI to Build Better Data Infrastructure (PRP Framework)** | Context Engineering framework for Snowflake data objects | [Watch](https://youtu.be/DUK39XqEVm0) |

Format this section as a visually appealing "📺 More From KC Labs AI" or similar header, with a brief intro like "Explore detailed tutorials on each integration demonstrated today:"
</video_log_section>

<success_criteria>
- Two files remain in meetup folder (plus datasets/ and qr_codes/ subdirectories)
- README.md is visually appealing with diagrams and clear sections
- All content is consolidated with no information loss
- Clear separation: audience-facing vs presenter-only content
- Demo prompts appear only in README.md
- Timing and narration appear only in PRESENTATION_GUIDE.md
- Video log section appears at the end of README.md with all 7 videos
</success_criteria>
