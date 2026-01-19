<objective>
Remove all references to sales data from the AWS S3/Athena integration video materials.

The video will focus exclusively on renewable energy data. All mentions of sales data, sales demos, or sales-related examples must be eliminated.
</objective>

<context>
Target folder: `/Users/kylechalmers/Development/data-ai-tickets-template/videos/integrating_aws_s3_athena/`

Files containing "sales" references that need editing:
- `README.md`
- `final_deliverables/script_outline.md`
- `example_workflow/README.md`

The video uses renewable energy data (`era-ren-collection.csv`) as its dataset.
</context>

<requirements>
1. Search each file for any mention of "sales", "Sales", or "SALES"
2. Remove or replace these references appropriately:
   - If it's a parallel example alongside renewable energy, remove the sales portion entirely
   - If it's the primary example, replace with renewable energy equivalent
   - Ensure the remaining text flows naturally after removal
3. Preserve all renewable energy data references and examples
4. Maintain document structure and formatting
</requirements>

<implementation>
For each affected file:
1. Read the current content
2. Identify all sales-related passages
3. Edit to remove sales references while keeping the document coherent
4. Verify no "sales" mentions remain

Use case-insensitive search to catch all variations.
</implementation>

<verification>
After editing, run:
```bash
grep -ri "sales" /Users/kylechalmers/Development/data-ai-tickets-template/videos/integrating_aws_s3_athena/
```
This should return no results.

Also verify:
- Documents still read coherently
- All renewable energy references are intact
- No orphaned sentences or broken formatting
</verification>

<success_criteria>
- Zero occurrences of "sales" (case-insensitive) in any file in the folder
- All documents maintain proper structure and readability
- Renewable energy data remains the sole dataset example
</success_criteria>
