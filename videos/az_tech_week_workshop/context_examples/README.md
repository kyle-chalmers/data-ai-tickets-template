# Context Engineering Resources

After the workshop, use these resources to go deeper with AI coding tools. Organized by learning path — start at the top and work your way down.

---

## Start Here — Official Anthropic Guides

| Resource | What You'll Learn |
|:---------|:------------------|
| [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) | The definitive guide — CLAUDE.md structure, context management, subagents, verification |
| [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | The theory behind context engineering — why context beats clever prompts |
| [How Anthropic Teams Use Claude Code](https://claude.com/blog/how-anthropic-teams-use-claude-code) | Real patterns from Anthropic's engineering, design, legal, and security teams |
| [CLAUDE.md Documentation](https://code.claude.com/docs/en/memory) | File hierarchy, imports, rules, auto memory — the complete reference |
| [Extend Claude Code](https://code.claude.com/docs/en/features-overview) | When to use CLAUDE.md vs skills vs agents vs MCP vs hooks |

---

## Frameworks for Structured Development

These frameworks add discipline and methodology on top of your AI coding tool.

| Framework | What It Does | Best For |
|:----------|:-------------|:---------|
| [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done) | Multi-phase autonomous execution with fresh contexts per phase. Solves "context rot" — quality degradation as the AI's context window fills up. | Structured, multi-session projects |
| [Superpowers](https://github.com/obra/superpowers) | Composable skills enforcing TDD, brainstorm→plan→implement→review discipline. | Full development lifecycle methodology |
| [GitHub Spec Kit](https://github.com/github/spec-kit) | Spec-driven development: Specify→Plan→Tasks→Implement. Works with Claude Code, Copilot, and Gemini CLI. | Cross-tool, spec-first workflows |
| [Context Engineering Intro](https://github.com/coleam00/context-engineering-intro) | PRP (Product Requirements Prompt) approach — beginner-friendly with full examples. | Getting started with context engineering |

---

## Community Collections

Find ready-made configurations, skills, and extensions.

| Collection | What's Inside |
|:-----------|:-------------|
| [Awesome Claude Code](https://github.com/hesreallyhim/awesome-claude-code) | Curated directory of skills, hooks, commands, plugins, and applications |
| [Awesome Claude Skills](https://github.com/travisvn/awesome-claude-skills) | Installable skill packages for Claude Code |
| [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | .cursorrules collection organized by framework (React, Node, TypeScript, etc.) |
| [claudefiles.dev](https://claudefiles.dev/) | CLAUDE.md generator with community sharing |

---

## Cross-Tool Reference — The 4 Layers Mapped

Every major AI coding tool now supports project-level context. The concepts are the same — the filenames differ.

### Layer 1: Instructions (Context Files)

| Tool | Context File | Created Via |
|:-----|:-------------|:------------|
| Claude Code | `CLAUDE.md` | `/init` |
| OpenCode | `AGENTS.md` | `/init` |
| Cursor | `.cursorrules` | Manual |
| GitHub Copilot | `.github/copilot-instructions.md` | Manual |
| Gemini CLI | `GEMINI.md` | Manual |
| Windsurf | `.windsurfrules` | Manual |

> **Tip:** Claude Code can import AGENTS.md via `@AGENTS.md` in your CLAUDE.md, so one file can serve both tools without duplication.

### Layer 2: Structure (Project Organization)

Both tools benefit from the same principles:
- **Clear directory naming** — AI reads folder names to understand purpose
- **README files** in key directories explaining what's there
- **Consistent naming conventions** — kebab-case files, PascalCase components, etc.
- **Separate concerns** — src/, tests/, docs/, config/

### Layer 3: Tools (CLI + MCP Connections)

| Capability | Claude Code | OpenCode |
|:-----------|:-----------|:---------|
| Add MCP server | `claude mcp add` | `opencode mcp add` |
| MCP config file | `.mcp.json` | `opencode.json` (`mcpServers` section) |
| OAuth MCP | Built-in OAuth flow | `opencode mcp auth` |
| CLI tools | Full bash access | Full bash access |

Both tools can use the same CLI tools (gh, bq, vercel, etc.) and MCP servers — the configuration format differs but the capability is equivalent.

### Layer 4: Workflows (Automation & Custom Commands)

| Capability | Claude Code | OpenCode |
|:-----------|:-----------|:---------|
| Custom commands | `.claude/skills/` (SKILL.md) | `.opencode/agents/` (markdown) |
| Subagents | `.claude/agents/` | `.opencode/agents/` (mode: subagent) |
| Hooks/automation | `hooks` in settings.json | Not available |
| Plugins | `.claude/plugins/` | Not available |
| Invoke command | `/skill-name` or auto-detect | `@agent-name` or Tab to switch |

> **Key difference:** Claude Code has a richer workflow layer (skills, hooks, plugins). OpenCode keeps it simpler with just agents and MCP. Start with the basics, add complexity as you level up.

---

## Recommended Reading

- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — practical section-by-section guide
- [Superpowers Blog Post](https://blog.fsck.com/2025/10/09/superpowers/) — Jesse Vincent's development methodology philosophy
- [Spec-Driven Development with AI](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) — GitHub's official blog post
- [OpenCode Agents Docs](https://opencode.ai/docs/agents) — how agents work in OpenCode

---

## Starter Templates

See the other files in this folder:
- **[CLAUDE_md_starter.md](./CLAUDE_md_starter.md)** — a fill-in-the-blank CLAUDE.md template organized by the 4 layers
- **[agents_and_skills_starter.md](./agents_and_skills_starter.md)** — starter templates for subagents and skills
