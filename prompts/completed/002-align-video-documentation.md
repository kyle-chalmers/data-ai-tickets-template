<objective>
Review and align all documentation files in the AWS S3 + Athena video project with the updated script outline.

The script has been updated with a new end-to-end workflow demo. Supporting documentation needs to match.
</objective>

<context>
Project location: `./videos/integrating_aws_s3_athena/`

The script outline (`final_deliverables/script_outline.md`) has been updated with:
- New demo dataset section (California Wildfire & Renewable Energy Projections)
- AWS Console navigation instructions
- End-to-end workflow demo (CSV → S3 → Athena → Query → Export)
- Glue references were removed, but user is reconsidering since Glue is part of AWS CLI capabilities

Files to review and align:
1. `./videos/integrating_aws_s3_athena/README.md` - Main project documentation
2. `./videos/integrating_aws_s3_athena/sample_data/README.md` - Sample data documentation
3. `./videos/integrating_aws_s3_athena/example_workflow/README.md` - Workflow documentation
</context>

<tasks>
1. **Read the current script outline** to understand the source of truth:
   - `./videos/integrating_aws_s3_athena/final_deliverables/script_outline.md`

2. **Review each documentation file** and assess:
   - Does it align with the script?
   - Is it still relevant or redundant?
   - Does it need updates to match the new workflow?

3. **Evaluate Glue coverage**:
   - Glue Data Catalog is used behind the scenes when creating Athena tables
   - The AWS CLI includes `aws glue` commands
   - Decide: Should Glue get a brief mention (one-liner) or stay removed?
   - Recommendation: If mentioning, keep it minimal - "Athena stores table metadata in the Glue Data Catalog automatically"

4. **Update or remove files** as needed:
   - Update content to match script
   - Remove redundant files if the script already covers the content
   - Consolidate if multiple files cover the same thing

5. **Ensure consistency** across:
   - Sample data (sales CSV) - same data used everywhere
   - S3 bucket names
   - Database/table names
   - Query examples
</tasks>

<output>
For each file reviewed, provide:
- Current status (aligned/misaligned/redundant)
- Action taken (updated/removed/kept as-is)
- Summary of changes made

If recommending Glue inclusion, add it to the script outline with minimal footprint.
</output>

<verification>
Before completing:
- All documentation files reviewed
- Script outline is the source of truth
- No conflicting information between files
- Glue decision documented and applied consistently
</verification>
</content>
</invoke>