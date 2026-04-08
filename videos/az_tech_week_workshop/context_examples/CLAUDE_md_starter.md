# CLAUDE.md / AGENTS.md Starter Template

> **Which file should I use?**
> - **Claude Code** reads `CLAUDE.md`
> - **OpenCode** reads `AGENTS.md`
> - The content structure is the same for both
> - If you use both tools, create a `CLAUDE.md` with `@AGENTS.md` on the first line so both read the same instructions

This template maps to the **4-layer Context Engineering framework** from the workshop. Fill in the `[brackets]` with your project's details. Delete any sections that don't apply.

**Target length:** Under 100 lines. Only include what the AI can't figure out by reading your code.

---

```
# Project: [Your Project Name]

## What This Project Does

[One paragraph: what it does, why it exists, who it's for]

## Code Style

- [Language-specific rules the AI can't infer, e.g. "Use ES modules (import/export), not CommonJS (require)"]
- [Formatting: "Prettier handles formatting — don't manually format code"]
- [Naming: "React components use PascalCase, utility files use kebab-case"]

## Standards

- [Testing: "Write tests for new features. Run with `npm test`"]
- [PRs: "Use conventional commits: feat:, fix:, docs:, refactor:"]
- [Reviews: "All PRs need one approval before merge"]

## Project Structure

- `src/` — [purpose, e.g. "application source code"]
- `src/components/` — [purpose, e.g. "React components"]
- `src/api/` — [purpose, e.g. "API route handlers"]
- `tests/` — [purpose, e.g. "test files, mirrors src/ structure"]
- `docs/` — [purpose, e.g. "documentation and guides"]

## Build & Run Commands

- Install dependencies: `[npm install / pnpm install / pip install -r requirements.txt]`
- Start dev server: `[npm run dev / python manage.py runserver]`
- Run tests: `[npm test / pytest]`
- Lint: `[npm run lint / ruff check]`
- Build: `[npm run build / make build]`
- Type check: `[npx tsc --noEmit / mypy .]`

## External Tools

- [CLI tool]: [what it does, e.g. "gh — GitHub CLI for PRs and issues"]
- [MCP server]: [what it connects to, e.g. "Notion MCP — pull data from project databases"]
- [Database]: [connection info, e.g. "PostgreSQL via DATABASE_URL env var"]

## Common Workflows

- To add a new API endpoint: [brief steps]
- To add a new component: [brief steps]
- To deploy: [brief steps]

## Gotchas

- [Non-obvious behavior, e.g. "Auth requires GITHUB_TOKEN env var — won't work without it"]
- [Known issues, e.g. "Tests fail if Redis isn't running locally"]
- [Quirks, e.g. "The /api/legacy/ routes use a different auth system — don't mix patterns"]

## Architecture Decisions

- [Key decision, e.g. "We use server components by default. Client components only when needed for interactivity."]
- [Key decision, e.g. "All data access goes through the /api/ layer, never directly from components."]
```

---

## Tips for Writing Your CLAUDE.md

1. **Start with `/init`** — both Claude Code and OpenCode can generate a starter file from your codebase
2. **Keep it under 100 lines** — longer files get ignored. If it's growing, split into separate files
3. **Only write what the AI can't see** — don't describe your code (the AI reads it). Describe your *conventions*
4. **Test it** — if the AI keeps doing something wrong, add a rule. If it already does something right, don't add a rule for it
5. **Iterate** — your CLAUDE.md will improve over time as you discover what the AI needs to know

## What NOT to Include

- Standard language conventions (the AI already knows these)
- Code style rules that a linter handles (use a linter instead)
- Detailed API documentation (link to docs, don't paste them)
- Information that changes frequently (it'll go stale)
- File-by-file descriptions of the codebase (the AI can read the files)
