<objective>
Restructure the AWS S3 + Athena video script with the user's updated hook intro, move definitions to the README, remove Workgroup definition, and renumber all sections.
</objective>

<context>
**Files to update:**
1. Google Drive script: `/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/AWS S3 Athena Integration Script Outline.md`
2. Repo script: `./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md`
3. Repo README: `./videos/integrating_aws_s3_athena/README.md`

Both script files should be identical after updates.
</context>

<requirements>

## 1. Replace the Hook Intro
Replace the existing HOOK INTRO section with this exact text:

```
## HOOK INTRO (30-45 seconds)

### First 5 Seconds
*(Standing, high energy, direct to camera)*

**Option 1:**
- "What if you didn't have to open the AWS Console again to query your data lake?"

### 6-15 Seconds
*(Set expectations)*

- "In this video, I'm going to show you how to connect the AWS CLI to your AWS data lake, and then - here's the real magic - how to let Claude Code handle the heavy lifting of working with S3 and Amazon Athena for you."

### Rest of Hook (Build the value proposition)

- "The real power here isn't just running AWS commands from your terminal."

- "Claude can take care of searching in S3 and querying Athena for you. You describe what you want in plain English. Claude figures out the right S3 paths, writes the Athena queries, handles the async execution."

- "Your job? Just QC the results."

- "This is delegation, not automation. Big difference."

[Personal anecdote opportunity: Share a specific example of time saved or a complex query Claude wrote for you]
- "For me, my team has multiple reporting jobs that produce csv files that are saved to AWS. If we want to query that data with Athena, we need to navigate to where the data is placed within S3 and then we need to set up the structure within Athena to properly query it, which means we were spending time searching and navigating through interfaces. But now with Claude, it can quickly interpret the information for where data is stored in our S3 buckets and quickley set up the queries from Athena to give me the information. Additionally, it can navigate to S3 and place files there when we need it to."

**Section Transition:**
- "So today to show you the power of this integration, I will first show you how to install the AWS CLI and cover the prerequisites you need to have in order to have it work. Then we will utilize the AWS CLI as if we are doing a real data analysis, placing data into S3 and then analyzing it using Athena, and compare that process to what we would have to do using the AWS Console."
```

## 2. Move Definitions to README
- Remove the DEFINITIONS section from the script
- Add the definitions to `./videos/integrating_aws_s3_athena/README.md` in an appropriate location (e.g., "Key Terms" or "Glossary" section)
- **Remove "Workgroup"** from the definitions list
- Keep these definitions: S3, Athena, Data Lake, CLI, IAM, External Table

## 3. Renumber Sections
Renumber the script sections to follow this order:

| New Section # | Content |
|---------------|---------|
| HOOK INTRO | (as provided above) |
| SECTION 1 | Key Terms/Definitions (brief verbal overview, point to README for details) |
| SECTION 2 | Setup and Configuration (Installing AWS CLI) |
| SECTION 3 | The Demo Dataset |
| SECTION 4 | AWS Console Navigation |
| SECTION 5 | S3 Operations |
| SECTION 6 | Athena Queries from CLI |
| SECTION 7 | Practical Workflow Demo |
| SECTION 8 | The Claude Integration |
| CLOSING | (keep as-is) |

## 4. Update Time Estimates
Adjust time estimates as needed to account for the new Section 1 (definitions overview should be brief, ~60 seconds).

</requirements>

<output>
Update these files:
1. `/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/AWS S3 Athena Integration Script Outline.md`
2. `./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md`
3. `./videos/integrating_aws_s3_athena/README.md` (add definitions/glossary section)

Both script files must be identical.
</output>

<verification>
Before completing, verify:
- [ ] Hook intro replaced with exact text provided
- [ ] Definitions moved to README.md
- [ ] Workgroup definition removed
- [ ] Sections renumbered correctly (1-8 + Hook + Closing)
- [ ] Both script files are identical
- [ ] Time estimates updated for new structure
</verification>
</content>
