# Ticket Structure Guide

This folder contains completed tickets organized by ticket ID following a standardized structure.

---

## Folder Structure

```
tickets/username/TICKET-XXX/
│
├── README.md                           # Complete documentation with assumptions
├── source_materials/                   # Original files and references
├── final_deliverables/                 # Ready-to-deliver outputs (numbered)
│   ├── 1_data_exploration.sql         # Numbered in review order
│   ├── 2_main_analysis.sql
│   ├── 3_results_summary.csv
│   └── qc_queries/                    # Quality control validation
├── original_code/                      # When modifying existing views/tables
├── exploratory_analysis/               # Working files (consolidated)
└── ticket_comment.txt                  # Final Jira comment (<100 words)
```

---

## Workflow

```
┌─────────────┐
│ Create      │──> git checkout -b TICKET-XXX
│ Branch      │
└──────┬──────┘
       ▼
┌─────────────┐
│ Setup       │──> mkdir -p tickets/username/TICKET-XXX/{source_materials,final_deliverables}
│ Folders     │
└──────┬──────┘
       ▼
┌─────────────┐
│ Develop     │──> Explore → Analyze → QC → Optimize
│ Solution    │
└──────┬──────┘
       ▼
┌─────────────┐
│ Document    │──> README.md + ticket_comment.txt
│ & Finalize  │
└──────┬──────┘
       ▼
┌─────────────┐
│ Create PR   │──> gh pr create (semantic title)
└──────┬──────┘
       ▼
┌─────────────┐
│ Merge &     │──> Update main README, backup to Drive
│ Archive     │
└─────────────┘
```

---

## Key Principles

- **Number deliverables** in logical review order (1_, 2_, 3_)
- **Update, don't sprawl** - Overwrite files rather than creating versions
- **Document assumptions** - Enumerate ALL assumptions in README.md
- **QC everything** - Validate record counts, duplicates, business logic
- **Keep it simple** - Minimal folder structure, essential files only

**See [CLAUDE.md](../../CLAUDE.md) for complete workflow documentation**
