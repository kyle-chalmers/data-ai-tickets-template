<objective>
Reorganize the AWS S3 + Athena README to match the flow of how information is presented in the video script.
</objective>

<context>
**Files:**
- Script: `./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md`
- README: `./videos/integrating_aws_s3_athena/README.md`

The script presents information in this order:
1. Hook Intro (value proposition, delegation vs automation)
2. Key Terms (definitions)
3. Setup and Configuration (AWS CLI installation)
4. The Demo Dataset (wildfire data, sales demo)
5. AWS Console Navigation (the "before" picture)
6. S3 Operations (CLI commands)
7. Athena Queries from CLI
8. Practical Workflow Demo (end-to-end: CSV → S3 → Athena → Query → Export)
9. The Claude Integration (the real workflow)
10. Closing

The README should mirror this flow so viewers reading along or referencing later find information in the same order they heard it.
</context>

<requirements>
1. **Analyze the script flow** - Identify the logical progression of topics
2. **Map README sections to script sections** - Determine which README content corresponds to which script section
3. **Reorganize README** - Reorder sections to match script flow
4. **Preserve all content** - Don't remove information, just reorganize
5. **Update section headers if needed** - Make headers consistent with script language

Suggested README structure (adapt as needed):
- Title and YouTube link
- The Value Proposition (from hook)
- Key Terms / Glossary
- Prerequisites
- Quick Start / Setup
- Demo Datasets
- S3 Operations (commands)
- Athena Queries (commands)
- Workflow Demo reference
- Claude Code Integration Examples
- Security Best Practices
- Files in This Project
- Resources
</requirements>

<output>
Update: `./videos/integrating_aws_s3_athena/README.md`

Also update the Google Drive copy to keep them in sync:
`/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/2 Project Files/Integrating S3 and Athena/README.md`
</output>

<verification>
Before completing:
- [ ] README sections follow the same logical order as the script
- [ ] All original content preserved (nothing deleted)
- [ ] Headers are clear and match script language where appropriate
- [ ] Both README copies are identical
</verification>
</content>
</invoke>