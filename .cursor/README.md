# Cursor Configuration

This directory contains Cursor-specific configuration migrated from the `.claude` setup. It provides rules, subagents, and slash commands for the data-tickets workflow.

## Structure

```
.cursor/
├── rules/
│   └── project-context.mdc    # Always-applied project context (role, permissions, QC standards)
├── agents/
│   ├── code-review-agent.md   # SQL/Python/notebook review
│   ├── docs-review-agent.md   # Documentation, URLs, folder coherence
│   ├── jira-ticket-transitioner.md  # Jira state transitions via acli
│   ├── qc-validator-agent.md  # QC validation checklist
│   └── sql-quality-agent.md   # SQL performance and best practices
├── commands/
│   ├── review-work.md         # /review-work [folder-path]
│   ├── save-work.md           # /save-work yes | no
│   ├── merge-work.md          # /merge-work
│   ├── initiate-request.md    # /initiate-request
│   ├── summarize-session.md   # /summarize-session
│   ├── google-drive-backup.md # /google-drive-backup
│   ├── jira-ticket-done.md    # /jira-ticket-done [TICKET-KEY]
│   ├── generate-data-object-prp.md   # /generate-data-object-prp [path]
│   └── prp-data-object-execute.md    # /prp-data-object-execute [PRP-path]
└── README.md                  # This file
```

## Mapping from .claude

| .claude | .cursor |
|---------|---------|
| agents/*.md | agents/*.md (subagents) |
| commands/*.md | commands/*.md |
| settings.json | rules/project-context.mdc (permissions, env, hooks) |
| CLAUDE.md / AGENTS.md | rules/project-context.mdc (condensed) + reference to root docs |

## Usage

- **Rules** apply automatically; project-context is always on.
- **Subagents** are invoked via @agent-name (e.g., @code-review-agent) or by commands that delegate to them.
- **Commands** are triggered with `/` (e.g., `/review-work videos/az_emerging_tech_meetup`). Text after the command is passed as input.

## Full Documentation

See [CLAUDE.md](../CLAUDE.md) and [AGENTS.md](../AGENTS.md) in the project root for complete instructions.
