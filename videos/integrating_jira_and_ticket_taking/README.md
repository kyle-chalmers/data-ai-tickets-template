# Atlassian CLI vs MCP: Comparison Guide

> **YouTube:** [The Guide for How to SUCCESSFULLY Integrate Claude & Claude Code in Your Team's Jira Ticket Workflow](https://www.youtube.com/watch?v=WRvgMzYaIVo)

Reference for understanding the differences between Atlassian CLI and MCP approaches for Jira and Confluence integration.

---

## Overview

Both tools provide access to Jira and Confluence with significant overlap in capabilities. The CLI excels at automation and scripting, while MCP is optimized for interactive exploration and natural language queries. The choice depends on your workflow needs, automation requirements, and integration preferences.

---

## Key Distinguishing Factors

| Feature | CLI (acli) | MCP |
|---------|-----------|-----|
| **Ticket Analysis** | Manual command chaining | ✅ Context-aware queries |
| **Context Retention** | None between commands | ✅ Full conversation history |
| **Token Usage** | ~100 tokens (output) | ~500-2,000+ tokens (data in context) |
| **Claude Desktop** | ❌ Not natively compatible | ✅ Native integration |
| **Bulk Updates** | ✅ Scripting/loops | ⚠️ One at a time |
| **Query Method** | Command syntax | Natural language |
| **Documentation Creation** | ⚠️ Requires conversion | ✅ Direct Confluence integration |

---

## Primary Use Cases

### CLI Strengths

**Automation & Scripting:**
- Bulk ticket updates and transitions
- CI/CD pipeline integration
- Scheduled status reports
- Batch comment posting

**Example:**
```bash
# Transition all tickets in a sprint to Done
for ticket in $(acli jira workitem list --jql "sprint = 123" --json | jq -r '.[].key'); do
  acli jira workitem transition --key "$ticket" --status "Done"
done
```

### MCP Strengths

**Interactive Exploration & Analysis:**
- Natural language ticket searches
- Conversational context across queries
- Pattern analysis across multiple tickets
- Integrated Confluence documentation
- Context-aware ticket management

**Example:**
```
"Show me TICKET-123 and find all related tickets. What patterns do you see?"
```

---

## Configuration & Authentication

### Atlassian CLI
- API token or OAuth web authentication
- Tokens expire in 1 year
- Manual token management
- Inherits user permissions

### Atlassian MCP
- OAuth only (browser-based)
- Automatic token refresh
- No manual management
- Scoped to selected products (Jira, Confluence, Compass)

---

## Workflow Integration

Use **both** together for optimal results:

| Phase | Tool | Purpose |
|-------|------|---------|
| Explore | MCP | Ticket discovery, requirements analysis |
| Analyze | MCP | Pattern identification, context-aware review |
| Document | MCP | Confluence page creation, formatting |
| Finalize | CLI | Batch updates, transitions, standardized comments |
| Automate | CLI | Scheduled jobs, CI/CD integration |

**Common Pattern:** Explore with MCP → Analyze with MCP → Automate with CLI

---

## Context & Token Considerations

### CLI
- Minimal token usage
- Direct API calls
- Predictable execution time
- No LLM processing overhead

### MCP
- Higher token consumption (LLM processing)
- Context maintained across queries
- Single request for complex operations
- Better for analytical tasks

---

## Setup

### CLI Setup
```bash
brew tap atlassian/homebrew-acli
brew install acli
acli jira auth login --web
```

[Full CLI Setup Guide](./ATLASSIAN_CLI_SETUP.md)

### MCP Setup
```bash
claude mcp add --scope user --transport sse atlassian https://mcp.atlassian.com/v1/sse
# In Claude Code session:
/mcp
# Follow OAuth flow in browser
```

[Full MCP Setup Guide](./ATLASSIAN_MCP_SETUP.md)


## Summary

**CLI:** Best for automation, scripting, CI/CD pipelines, and batch operations.

**MCP:** Best for interactive exploration, natural language queries, pattern analysis, and integrated documentation.

**Together:** Complementary tools that enable complete ticket workflow from exploration to automation.

---

## Setup Guides

- [Atlassian CLI Setup](./ATLASSIAN_CLI_SETUP.md)
- [Atlassian MCP Setup](./ATLASSIAN_MCP_SETUP.md)

---

**Last Updated:** November 2025
