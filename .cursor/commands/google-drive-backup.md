# Backup to Google Drive

Backs up project deliverables to Google Drive for sharing and archiving.

**Requires explicit user permission before executing.**

## When to Use

- Project completion
- Major milestone reached
- Before creating PR
- When sharing with stakeholders
- Archiving completed work

## What it does

1. **Identifies Deliverables** – final_deliverables/, README.md, key reports and outputs, production files.
2. **Determines Google Drive Path** – Shared team drives or personal drives, structured folders. Common patterns:
   - `Shared drives/[Team Name]/Projects/[user]/[project]/`
   - `My Drive/Data Analysis/[project]/`
3. **Performs Backup** – Remove old backup if exists, copy complete structure, preserve folder organization, verify success.
4. **Provides Confirmation** – Show path, confirm files backed up, suggest next steps.

## What Gets Backed Up

- All files in final_deliverables/
- README.md
- QC queries and results
- Key notebooks or scripts
- Reports or presentations

**Not included:** exploratory_analysis/, .git, temporary or cache files.

## Important Notes

- **Always ask permission** before executing.
- Overwrites previous backups in same location.
- Preserves folder structure.
- Verify Google Drive is mounted and accessible.

## Configuration

See CLAUDE.md for Google Drive base path and team folder configuration.
