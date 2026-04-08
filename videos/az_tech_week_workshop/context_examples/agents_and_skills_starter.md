# Subagent & Skill Starter Templates

After you have a CLAUDE.md or AGENTS.md, the next step is creating **subagents** (isolated workers) and **skills** (reusable knowledge/workflows).

> **When to use which:**
> - **Subagents** = isolated context + delegated tasks. The subagent works separately and returns a summary. Your main conversation stays clean.
> - **Skills** = loaded into your current context when relevant. Adds knowledge or triggers workflows you invoke with `/skill-name`.

---

## Subagent Template

Save as `.claude/agents/[name].md` (Claude Code) or `.opencode/agents/[name].md` (OpenCode).

### Claude Code Format

```yaml
---
name: [agent-name]
description: [When Claude should delegate to this agent — be specific so Claude knows when to use it]
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a [role] specializing in [domain].

## Your Responsibilities
- [Specific task this agent handles]
- [Another task]
- [Another task]

## Standards
- [Quality expectations for this agent's output]
- [Output format: "Return a bullet-point summary under 200 words"]

## Context
- [Key files or directories to focus on]
- [Domain knowledge the agent needs]
```

### OpenCode Format

```json
{
  "description": "[When to use this agent]",
  "mode": "subagent",
  "model": "[model name]",
  "permission": {
    "edit": "deny",
    "bash": "ask"
  }
}
```

Or as a markdown file in `.opencode/agents/[name].md` with the system prompt as content.

### Example: Code Reviewer

```yaml
---
name: code-reviewer
description: Reviews code for quality, security, and best practices. Use after significant code changes or before PRs.
tools: Read, Grep, Glob
model: sonnet
---

You are a senior code reviewer. Analyze code for:

- Security vulnerabilities (injection, auth flaws, exposed secrets)
- Performance issues (N+1 queries, unnecessary re-renders, missing indexes)
- Code quality (naming, structure, duplication, error handling)
- Best practices for the language and framework in use

Provide specific line references and suggested fixes. Be concise — focus on issues that matter, not style nitpicks.
```

---

## Skill Template (Claude Code only)

Save as `.claude/skills/[name]/SKILL.md`.

```yaml
---
name: [skill-name]
description: [What this skill does — Claude uses this to decide when to load it automatically]
---

[Instructions for Claude when this skill is active.
Can include step-by-step workflows, reference material, or domain knowledge.]
```

### Example: Deploy Workflow

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy the application following these steps:

1. Run the test suite: `npm test`
2. Check for lint errors: `npm run lint`
3. Build the project: `npm run build`
4. Deploy to Vercel: `vercel --prod`
5. Verify the deployment is live
6. Create a git tag for the release

Stop and report if any step fails.
```

> `disable-model-invocation: true` means only YOU can trigger this with `/deploy` — Claude won't run it automatically.

---

## Next Steps

1. **Start with one subagent** — a code reviewer is a great first choice
2. **Start with one skill** — your deploy workflow or a common task you repeat
3. **Iterate** — add more as you discover patterns in your work
4. **Share with your team** — commit `.claude/agents/` and `.claude/skills/` to version control
