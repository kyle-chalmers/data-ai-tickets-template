# Backup to Google Drive

Backs up your project deliverables to Google Drive for sharing and archiving.

## Usage

Run this command when you want to backup your work to Google Drive.

## When to Use

- Project completion
- Major milestone reached
- Before creating PR
- When sharing with stakeholders
- Archiving completed work

## What it does

### 1. Identifies Deliverables
Locates files to backup:
- final_deliverables/ folder
- README.md
- Key reports and outputs
- Production files

### 2. Determines Google Drive Path
Identifies appropriate Google Drive location:
- Shared team drives for collaborative work
- Personal drives for individual projects
- Structured folders maintaining organization

**Common patterns:**
- `Shared drives/[Team Name]/Projects/[user]/[project]/`
- `My Drive/Data Analysis/[project]/`
- Custom team-specific folder structures

### 3. Performs Backup
- Removes old backup if exists
- Copies complete project structure
- Maintains folder organization
- Verifies successful backup

### 4. Provides Confirmation
- Shows Google Drive path
- Confirms files backed up
- Suggests next steps (sharing, etc.)

## Example Usage

```
You: "/google-drive-backup"
Claude: "I'll backup your project to Google Drive."
        [Identifies deliverables]
        [Determines backup location]
        [Copies to Google Drive]
        "Backup complete!"
        "Location: Shared drives/Analytics Team/Projects/username/customer-churn-analysis/"
```

## What Gets Backed Up

Typical backup includes:
- All files in final_deliverables/
- README.md
- QC queries and results
- Key notebooks or scripts
- Any reports or presentations

**Not included by default:**
- exploratory_analysis/ folder
- .git folder
- Temporary or cache files

## Important Notes

- **Requires permission** to execute
- Overwrites previous backups in same location
- Preserves folder structure
- Uses `cp -r` to maintain file attributes
- Verifies Google Drive is mounted and accessible

## Configuration

Customize Google Drive paths in your team's CLAUDE.md or as environment variables:

```markdown
## Google Drive Configuration
GOOGLE_DRIVE_BASE="/Users/[username]/Library/CloudStorage/GoogleDrive-[email]/Shared drives"
TEAM_FOLDER="Analytics Team"
```

## Checklist Before Backup

Ensure ready:
- [ ] Final deliverables complete
- [ ] README.md finalized
- [ ] QC completed and documented
- [ ] Files organized and named properly
- [ ] Ready for stakeholder access
- [ ] Google Drive mounted and accessible

## Troubleshooting

**Google Drive not mounted:**
- Verify Google Drive desktop app is running
- Check Google Drive folder is accessible
- Confirm correct path in configuration

**Permission errors:**
- Ensure you have write access to target folder
- Check shared drive permissions
- Verify folder structure exists

**Backup verification:**
- Navigate to Google Drive location
- Confirm file count matches
- Check file sizes are correct
- Test opening a few key files

---

Use this to archive and share your completed work with stakeholders!
