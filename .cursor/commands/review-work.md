# Review Work

Reviews work in a folder by running appropriate subagents based on content.

**Argument**: The folder path to review. If the user types text after `/review-work`, that is the folder path (e.g., `/review-work videos/claude_code_overview` or `/review-work tickets/kyle/DS-123`).

## Process

1. **Determine folder path** from user input (text after the command). If no path provided, ask for it.
2. **Explore the folder** to understand its contents.
3. **Identify applicable subagents** based on file types present.
4. **Delegate to appropriate subagents** based on folder contents. Use @code-review-agent, @sql-quality-agent, @qc-validator-agent, @docs-review-agent. Run applicable agents (in parallel when efficient).
5. **Provide consolidated review summary** with findings from each agent.

## Agent Selection

| Content Detected | Agents Triggered |
|------------------|------------------|
| `*.sql` files | @code-review-agent, @sql-quality-agent |
| `*.py` files | @code-review-agent |
| `*.ipynb` files | @code-review-agent |
| `qc_queries/` folder | @qc-validator-agent |
| `README.md` or `*.md` files | @docs-review-agent |

## Execution Steps

1. List all files and subdirectories in the target folder.
2. Categorize contents: count `.sql`, `.py`, `.ipynb`, `.md` files; check for `qc_queries/` subfolder and `README.md`.
3. For each applicable agent, delegate with the folder path and clear instructions to review that folder.
4. Run agents in parallel for efficiency where possible.
5. Consolidate all findings into a unified report.

## Output Format

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

- If no applicable content is found, report that and suggest what might be missing.
- The docs-review-agent also checks overall folder coherence (README matches contents, files documented, structure consistent).
- Consolidate findings while preserving each agent's perspective.
