# Cursor Setup Guide

How to configure Cursor for the demo comparison with Claude Code.

---

## Install Cursor

1. Download from [cursor.com](https://www.cursor.com/)
2. Install and open the repository in Cursor

---

## Context Engineering for Cursor

### AGENTS.md (Universal)

Cursor automatically reads `AGENTS.md` files. The repo-level `/AGENTS.md` contains the same 700+ lines of instructions as CLAUDE.md. Cursor will pick this up automatically.

**Hierarchy:** Cursor reads the nearest AGENTS.md in the directory tree. For the demo workspace, the repo-root AGENTS.md applies.

### .cursorrules (Cursor-Specific)

Optionally create a `.cursorrules` file at the repo root for Cursor-specific instructions. This is read in addition to AGENTS.md.

Example `.cursorrules` for this project:
```
You are working in a data engineering repository. Follow these Cursor-specific guidelines:

1. Use the integrated terminal for CLI commands (databricks, aws, etc.)
2. When creating Python files, use the file tree to organize output
3. For Databricks job configs, create valid JSON files
4. Always show inline diffs before applying changes
```

### Cursor Rules Directory (Alternative)

Cursor also supports `.cursor/rules/` directory with `.mdc` files for more granular control:
```
.cursor/
└── rules/
    ├── general.mdc        # General project rules
    ├── python.mdc         # Python-specific rules
    └── databricks.mdc     # Databricks-specific rules
```

---

## What Transfers from Claude Code to Cursor

| Feature | Claude Code | Cursor Equivalent |
|---------|-------------|-------------------|
| CLAUDE.md | Yes (auto-loaded) | AGENTS.md (auto-loaded) |
| Role definition | In CLAUDE.md | In AGENTS.md |
| Coding standards | In CLAUDE.md | In AGENTS.md |
| CLI tool reference | In CLAUDE.md | In AGENTS.md |
| Custom agents | `.claude/agents/` (4 agents) | No equivalent |
| Custom commands | `.claude/commands/` (6 commands) | No equivalent |
| MCP servers | Configured in Claude | Not applicable |
| CLI-native execution | Direct terminal | IDE terminal |

---

## What Does NOT Transfer

1. **Custom Agents** - Claude Code's `.claude/agents/` directory has specialized agents for code review, SQL quality, QC validation, and docs review. Cursor has no equivalent.

2. **Custom Commands** - `/save-work`, `/review-work`, `/initiate-request`, etc. are Claude Code specific. In Cursor, these would be manual steps.

3. **Direct CLI Integration** - Claude Code runs in the terminal with native access to all CLI tools. Cursor accesses the terminal through its IDE, which adds a layer of indirection.

---

## Cursor Agent Mode

For the demo, use Cursor's **Agent mode** (not Ask or Edit mode):

1. Open Cursor's AI panel (Cmd+L or Ctrl+L)
2. Select "Agent" mode from the dropdown
3. Paste the demo prompt
4. Agent mode allows Cursor to:
   - Create and edit files
   - Run terminal commands
   - Read existing files for context
   - Make multi-step changes

---

## Demo Recording Tips

- Start with a clean `demo_workspace/cursor/` directory
- Show the AGENTS.md file briefly before starting
- Use Agent mode for the full workflow
- Narrate differences from the Claude Code experience as you go
- Note any places where you need to manually intervene vs Claude Code
