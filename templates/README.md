# CLAUDE.md Templates

This directory contains domain-specific CLAUDE.md templates optimized for different types of projects.

## Template Selection Guide

| Template | Best For | Key Features |
|----------|----------|--------------|
| [CLAUDE-base.md](./CLAUDE-base.md) | Starting point for any project | Minimal (~60 lines), universal principles |
| [CLAUDE-data-analysis.md](./CLAUDE-data-analysis.md) | SQL-first analysis, BI, Snowflake | Database tools, QC requirements, stakeholder communication |
| [CLAUDE-data-engineering.md](./CLAUDE-data-engineering.md) | ETL, pipelines, data platforms | Pipeline structure, orchestration, data quality |
| [CLAUDE-software-engineering.md](./CLAUDE-software-engineering.md) | Application development | Code architecture, testing, API patterns |
| [CLAUDE-devops-infrastructure.md](./CLAUDE-devops-infrastructure.md) | CI/CD, cloud, deployments | Environment matrix, IaC, change management |
| [CLAUDE-documentation-research.md](./CLAUDE-documentation-research.md) | Technical writing, research | Style guide, source management, document types |

## How to Use

1. **Choose a template** based on your primary work type
2. **Copy to your project root** as `CLAUDE.md`
3. **Fill in placeholders** marked with `[YOUR_...]` or `[PLACEHOLDER]`
4. **Remove guidance comments** (HTML `<!-- -->`) once filled
5. **Add project-specific sections** as needed

## Template Design Principles

Based on industry best practices research:

- **Concise**: Under 300 lines ideally, ~60 lines optimal
- **WHY-WHAT-HOW**: Project purpose, tech stack, build/test commands
- **Progressive disclosure**: Reference external docs, don't embed everything
- **Living document**: Update when agents make consistent mistakes
- **Universal focus**: Task-specific workflows belong in skills/commands

## Placeholder Format

Templates use consistent placeholder markers:

```markdown
<!--
GUIDANCE: [Explanation of what to include]
-->

### Section Name
<!-- DESCRIBE: [What specific info goes here] -->
[YOUR_PLACEHOLDER_NAME]
```

- HTML comments (`<!-- -->`) are hidden when rendered
- `[YOUR_...]` markers indicate fill-in content
- Guidance is grouped with relevant sections

## Customization Tips

1. **Start minimal**: Use base template, add sections as needed
2. **Don't duplicate linters**: Code style belongs in deterministic tools (eslint, ruff)
3. **Link, don't embed**: Reference detailed docs instead of copying content
4. **Test and iterate**: Update when Claude makes repeated mistakes
