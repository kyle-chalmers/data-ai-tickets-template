# Atlassian MCP Setup

Quick setup guide for Atlassian MCP - enables Claude to interact with Jira, Confluence, and Compass.

## Quick Start (2 minutes)

```bash
# 1. Add to Claude Code at USER LEVEL (available in all projects)
claude mcp add --scope user --transport sse atlassian https://mcp.atlassian.com/v1/sse

# 2. Verify
claude mcp list
# Should show: atlassian - ⚠ Needs authentication

# 3. Authenticate
# In any Claude Code session, type:
/mcp
# Follow the OAuth flow in your browser to connect your Atlassian account

# 4. Confirm connection
claude mcp list
# Should show: atlassian - ✓ Connected
```

**Time:** 2-3 minutes | **Scope:** User-level (all projects)

---

## Authentication

The Atlassian MCP uses **OAuth 2.0** authentication. No API tokens or manual configuration needed.

### Authentication Steps

1. **Type `/mcp` in any Claude Code session**
2. **Select "Connect Atlassian Account"** from the menu
3. **Browser will open** - Log in to your Atlassian account
4. **Grant access** to your Jira, Confluence, and/or Compass instances
5. **Done** - Tokens stored securely and refreshed automatically

### Requirements

- Atlassian Cloud account with access to Jira/Confluence/Compass
- Modern browser (disable pop-up blockers during authentication)
- No API tokens or manual configuration required

---

## What You Can Do

### Jira Capabilities

**Issue Management:**
- View, create, edit, and transition issues
- Search using JQL (Jira Query Language)
- Add comments to issues
- Get available transitions
- Lookup user account IDs
- Manage issue metadata

**Project Operations:**
- List visible projects
- Get project issue types
- Access project configuration

### Confluence Capabilities

**Content Management:**
- Get and list spaces
- Read page content (converted to Markdown)
- Create and update pages
- Navigate page hierarchies
- Get all pages within a space

**Comments & Collaboration:**
- View and create footer comments
- View and create inline comments
- Filter by resolution status

**Search:**
- Search using CQL (Confluence Query Language)
- Filter by title, type, labels, dates

### Compass Capabilities

**Component Management:**
- List and get components
- Create new components
- Create relationships between components
- Manage custom field definitions

### Rovo Search

**Unified Search:**
- Search across Jira and Confluence simultaneously
- Natural language queries
- Fetch details by ARI (Atlassian Resource Identifier)

---

## Example Use Cases

**Ticket Workflows:**
```
You: "Show me all open tickets assigned to me"
Claude: [Searches Jira and displays your tickets]

You: "Add a comment to TICKET-123 with the analysis results"
Claude: [Adds comment to the ticket]

You: "Transition TICKET-123 to Done"
Claude: [Updates ticket status]
```

**Documentation:**
```
You: "Create a Confluence page documenting this analysis"
Claude: [Creates page with your content]

You: "Update the Data Catalog page with this new table"
Claude: [Updates existing Confluence page]
```

**Search & Discovery:**
```
You: "Find all tickets related to payment processing"
Claude: [Searches using JQL and returns results]

You: "Show me the deployment runbook page"
Claude: [Finds and displays Confluence page content]
```

---

## Troubleshooting

### Authentication Issues

**Connection fails:**
```bash
# Remove and re-add
claude mcp remove atlassian -s user
claude mcp add --scope user --transport sse atlassian https://mcp.atlassian.com/v1/sse
# Then authenticate again with /mcp
```

**OAuth flow blocked:**
- Check that pop-up blockers are disabled
- Verify you have an active Atlassian Cloud account
- Ensure you have access to at least one Jira/Confluence/Compass instance

**Tools not appearing in conversations:**
- Start a new chat session after authenticating
- Type `/mcp` to verify connection status
- Check that you granted access to the correct instances during OAuth

### Known Limitations

**SSE Transport Deprecation:**
- SSE (Server-Sent Events) transport is being phased out
- Atlassian is working on stability improvements
- Some users report connection drops after a few hours

**Reliability:**
- May require re-authentication after extended periods
- Connection can become unresponsive - restart Claude Code if needed

### Verify Access

**Test in Claude Code:**
```
# Try a simple query
You: "List my open Jira tickets"
Claude: [Should return your tickets or prompt for specifics]

# Try Confluence
You: "Show me available Confluence spaces"
Claude: [Should list your spaces]
```

---

## vs. Atlassian CLI

**Use MCP for:**
- Interactive conversations with Claude
- Natural language queries
- Integrated analysis and documentation
- Context-aware ticket management
- Reduced command memorization

**Use CLI (`acli`) for:**
- Scripting and automation
- CI/CD pipelines
- Batch operations
- Precise control over API calls
- Local development workflows

**Best Practice:** Use both together
- MCP for interactive work in Claude Code
- CLI for scripts, automation, and quick terminal commands

**Detailed Comparison:** See [CLI vs. MCP Comparison Guide](./README.md)

---

## Important Notes

- **OAuth-based:** No API tokens needed - browser authentication only
- **Auto-refresh:** Tokens refreshed automatically (no manual management)
- **Word limits:** Follow CLAUDE.md guidelines - 100 words max for comments
- **Scope:** User-level means available across all your Claude Code projects

---

**Transport:** SSE (Server-Sent Events)
**Documentation:** https://support.atlassian.com/atlassian-rovo-mcp-server/
**MCP URL:** https://mcp.atlassian.com/v1/sse