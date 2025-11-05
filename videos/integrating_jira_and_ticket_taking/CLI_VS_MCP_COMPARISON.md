# Atlassian CLI vs. MCP: When to Use Each

Comparison guide for choosing between Atlassian CLI (acli) and Atlassian MCP Server for Jira/Confluence integration.

---

## Quick Decision Guide

**Use CLI (`acli`) for:**
- Scripting and automation
- CI/CD pipelines
- Batch operations
- Precise control over API calls
- Local development workflows

**Use MCP for:**
- Interactive conversations with Claude
- Natural language queries
- Integrated analysis and documentation
- Context-aware ticket management
- Reduced command memorization

**Best Practice:** Use both together
- MCP for interactive work in Claude Code
- CLI for scripts, automation, and quick terminal commands

---

## Detailed Comparison

| Feature | CLI (acli) | MCP Server |
|---------|-----------|------------|
| **Setup** | Homebrew install + auth | Add to Claude + OAuth |
| **Authentication** | API token or OAuth | OAuth only |
| **Usage** | Terminal commands | Natural language in Claude |
| **Scripting** | Excellent | Not applicable |
| **Automation** | Excellent | Not available |
| **Learning Curve** | Moderate (learn commands) | Low (conversational) |
| **Precision** | Exact control | AI-interpreted |
| **Context Awareness** | None | Full conversation context |
| **Batch Operations** | Easy with loops/scripts | One at a time |
| **Documentation** | Man pages, help flags | Conversational guidance |
| **Integration** | Shell scripts, CI/CD | Claude Code sessions |

---

## Use Case Examples

### Scenario 1: Viewing a Single Ticket

**CLI:**
```bash
acli jira workitem view TICKET-123
```

**MCP (in Claude):**
```
You: "Show me TICKET-123"
Claude: [Retrieves and displays ticket details]
```

**Winner:** **Tie** - Both equally simple

---

### Scenario 2: Bulk Operations

**CLI:**
```bash
# Transition all tickets in a sprint to Done
for ticket in $(acli jira workitem list --jql "sprint = 123" --json | jq -r '.[].key'); do
  acli jira workitem transition --key "$ticket" --status "Done"
done
```

**MCP:**
Not practical for bulk operations - would require individual requests

**Winner:** **CLI** - Much better for automation

---

### Scenario 3: Complex Analysis with Context

**CLI:**
```bash
# Would require multiple commands and manual correlation:
acli jira workitem view TICKET-123 > ticket.txt
acli jira workitem list --jql "related to TICKET-123" > related.txt
# Then manually analyze the files
```

**MCP (in Claude):**
```
You: "Show me TICKET-123 and find all related tickets. What patterns do you see in the descriptions?"
Claude: [Retrieves tickets, analyzes content, identifies patterns, provides insights]
```

**Winner:** **MCP** - Better for contextual analysis

---

### Scenario 4: Creating Documentation from Tickets

**CLI:**
```bash
# Manual process - export data then format separately
acli jira workitem view TICKET-123 --json > data.json
# Would need separate script to format for documentation
```

**MCP (in Claude):**
```
You: "Create a Confluence page documenting the solution from TICKET-123"
Claude: [Retrieves ticket, formats content, creates Confluence page]
```

**Winner:** **MCP** - Integrated workflow

---

### Scenario 5: CI/CD Integration

**CLI:**
```bash
# In GitHub Actions or Jenkins
- name: Update Jira
  run: |
    echo "$JIRA_TOKEN" | acli jira auth login \
      --site "company.atlassian.net" \
      --email "bot@company.com" \
      --token
    acli jira workitem transition --key "$TICKET_ID" --status "Deployed"
```

**MCP:**
Not available in CI/CD environments

**Winner:** **CLI** - Only option for automation

---

### Scenario 6: Ad-hoc Exploration During Analysis

**CLI:**
```bash
# Multiple separate commands needed
acli jira workitem list --jql "project = BI"
acli jira workitem view TICKET-456
acli jira workitem view TICKET-789
# Manual correlation of information
```

**MCP (in Claude):**
```
You: "What BI tickets are related to payment processing?"
Claude: [Searches tickets, identifies relevant ones, summarizes findings]

You: "Show me the most recent one"
Claude: [Retrieves and displays details, maintains context]

You: "Add this analysis to the ticket comments"
Claude: [Formats and posts comment]
```

**Winner:** **MCP** - Conversational context + integrated actions

---

## Integration Strategies

### Development Workflow

**Morning standup preparation:**
```bash
# CLI: Quick status check
acli jira workitem list --assignee "me" --status "In Progress"
```

**During ticket work (in Claude Code):**
```
# MCP: Interactive exploration
"Show me TICKET-123 requirements"
"Search Confluence for related documentation"
"What similar tickets exist?"
```

**After analysis completion:**
```bash
# CLI: Scripted updates
acli jira workitem comment --key "TICKET-123" --body "$(cat summary.txt)"
acli jira workitem transition --key "TICKET-123" --status "Done"
```

### Ticket Resolution Pattern

1. **Start with MCP** - Explore requirements, search context
2. **Analyze with Claude + MCP** - Use conversational interface for investigation
3. **Document with MCP** - Create Confluence pages, format findings
4. **Finalize with CLI** - Batch updates, transitions, standardized comments

### Automation Pattern

1. **Script with CLI** - Scheduled jobs, status updates, bulk operations
2. **Monitor with MCP** - Ad-hoc checks during Claude Code sessions
3. **Report with both** - CLI exports data, MCP formats and documents

---

## Authentication Comparison

### CLI (acli)

**Methods:**
- API token (manual creation)
- OAuth web flow

**Token Management:**
- Tokens expire in 1 year (after Dec 2024)
- Manual rotation required
- Store securely in files or environment variables

**Scopes:**
- Inherits user permissions
- Same access as your Atlassian account

### MCP

**Methods:**
- OAuth only (browser-based)

**Token Management:**
- Automatic refresh
- No manual management needed
- Stored securely by Claude

**Scopes:**
- Selected during OAuth flow
- Can grant access to specific products (Jira, Confluence, Compass)

---

## Performance Considerations

### CLI

**Pros:**
- Fast direct API calls
- No LLM processing overhead
- Predictable execution time

**Cons:**
- Multiple commands needed for complex tasks
- Manual result correlation

### MCP

**Pros:**
- Single natural language request
- Automatic result synthesis
- Context maintained across queries

**Cons:**
- LLM processing time
- Token usage considerations
- May require clarification for ambiguous requests

---

## Cost Considerations

### CLI

- **Free** - No additional costs beyond Atlassian licensing
- No API rate limit concerns for normal usage
- No LLM token costs

### MCP

- **LLM token usage** - Each request uses Claude tokens
- More expensive for high-volume operations
- Better value for complex analysis requiring interpretation

---

## Recommendations by Role

### Data Analyst / BI Engineer

**Primary:** MCP
- Natural language ticket exploration
- Integrated documentation creation
- Context-aware analysis

**Secondary:** CLI
- Export data for reports
- Bulk status updates
- Scheduled automation

### DevOps / Platform Engineer

**Primary:** CLI
- CI/CD integration
- Deployment automation
- Infrastructure scripts

**Secondary:** MCP
- Ad-hoc investigation
- Documentation updates
- Incident exploration

### Manager / Stakeholder

**Primary:** MCP
- Easy ticket review without command knowledge
- Natural language searches
- Quick status checks

**Secondary:** CLI (via team automation)
- Team dashboards
- Automated reporting

---

## Quick Reference

**Choose CLI when you need to:**
- ✅ Automate repetitive tasks
- ✅ Integrate with scripts or CI/CD
- ✅ Perform bulk operations
- ✅ Have zero LLM token costs
- ✅ Execute precise API calls

**Choose MCP when you need to:**
- ✅ Explore tickets conversationally
- ✅ Analyze patterns across tickets
- ✅ Create documentation from findings
- ✅ Work within Claude Code sessions
- ✅ Maintain context across operations

**Use both when you need:**
- ✅ End-to-end ticket workflow (explore → analyze → automate)
- ✅ Flexibility for different scenarios
- ✅ Best tool for each specific task

---

## Related Documentation

- [Atlassian CLI Setup](./ATLASSIAN_CLI_SETUP.md)
- [Atlassian MCP Setup](./ATLASSIAN_MCP_SETUP.md)

---

**Last Updated:** November 2024
