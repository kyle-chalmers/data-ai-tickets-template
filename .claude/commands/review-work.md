# Review Work

Reviews work in a folder by automatically running appropriate agents based on content.

## Arguments: $ARGUMENTS

The folder path to review (required).

## Usage

```
/review-work [folder-path]
```

## Example

```
/review-work videos/claude_code_overview
/review-work tickets/kyle/DS-123
/review-work projects/analysis/customer-churn
```

## Process

1. **Explore the folder** at $ARGUMENTS to understand its contents
2. **Identify applicable agents** based on file types present
3. **Run all applicable agents in parallel** using the Task tool
4. **Provide consolidated review summary** with findings from each agent

## Agent Selection

Automatically select agents based on folder contents:

| Content Detected | Agents Triggered |
|------------------|------------------|
| `*.sql` files | `code-review-agent`, `sql-quality-agent` |
| `*.py` files | `code-review-agent` |
| `*.ipynb` files | `code-review-agent` |
| `qc_queries/` folder | `qc-validator-agent` |
| `README.md` or `*.md` files | `docs-review-agent` |

## Available Agents

1. **code-review-agent** - Reviews SQL, Python, and notebooks for best practices and quality standards
2. **sql-quality-agent** - Specialized SQL review focusing on performance optimization and anti-patterns
3. **qc-validator-agent** - Validates QC query coverage, execution evidence, and sign-off readiness
4. **docs-review-agent** - Reviews documentation for URLs, structure, style, and folder coherence

## Execution Steps

1. List all files and subdirectories in $ARGUMENTS
2. Categorize contents:
   - Count `.sql`, `.py`, `.ipynb`, `.md` files
   - Check for `qc_queries/` subfolder
   - Check for `README.md`
3. For each applicable agent, launch using the Task tool with:
   - The folder path as context
   - Clear instructions to review that specific folder
4. Run agents in parallel for efficiency
5. Consolidate all findings into a unified report

## Output Format

Provide a consolidated report:

```markdown
## Work Review: [folder-path]

### Folder Contents
- [Summary of what was found]

### Agents Run
- [List each agent triggered and why]

### Code Review Findings
[Summary from code-review-agent if run]

### SQL Quality Findings
[Summary from sql-quality-agent if run]

### QC Validation Findings
[Summary from qc-validator-agent if run]

### Documentation Review Findings
[Summary from docs-review-agent if run]

### Overall Assessment
- **Ready for Review**: [Yes/No/Needs Work]
- **Priority Issues**: [List top 3 issues to address]
- **Recommendations**: [Key next steps]
```

## Notes

- If no applicable content is found, report that and suggest what might be missing
- The docs-review-agent also checks overall folder coherence (README matches contents, files are documented, structure is consistent)
- All agents run in parallel for faster reviews
- Review findings are consolidated but each agent's perspective is preserved
