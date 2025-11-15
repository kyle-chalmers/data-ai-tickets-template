# Databricks CLI vs MCP: Comparison Guide

Reference for understanding the differences between Databricks CLI and MCP approaches for integrating Databricks with Claude.

---

## Overview

Both tools provide access to Databricks resources with significant overlap in capabilities. The CLI excels at workspace management, job orchestration, and automation, while MCP is optimized for interactive data exploration and Unity Catalog access. The choice depends on your workflow needs, whether you prioritize automation or conversational analysis.

---

## Key Distinguishing Factors

| Feature | CLI | MCP (Managed) | MCP (databrickslabs) |
|---------|-----|---------------|---------------------|
| **SQL Queries** | ✅ Direct execution | ✅ Conversational | ✅ Conversational |
| **Job Management** | ✅ Full control | ❌ Limited | ❌ Limited |
| **Workspace Operations** | ✅ Complete access | ❌ Not supported | ❌ Not supported |
| **Unity Catalog Access** | ⚠️ Manual queries | ✅ Auto-discovery | ✅ Schema-level |
| **Genie Spaces** | ❌ Not supported | ✅ Native integration | ⚠️ Basic support |
| **Vector Search** | ⚠️ SQL only | ✅ Integrated | ❌ Limited |
| **Claude Desktop** | ❌ Not compatible | ✅ Native | ✅ Compatible |
| **Production Support** | ✅ Official | ✅ Official SLA | ❌ Experimental |
| **Setup Complexity** | Low (5 min) | Very Low (ready) | High (15 min) |
| **Authentication** | OAuth/PAT | Workspace-integrated | PAT only |

---

## Primary Use Cases

### CLI Strengths

**Workspace & Job Management:**
- Create, run, and manage Databricks jobs
- Export and import notebooks
- Cluster operations (start, stop, configure)
- DBFS file operations
- Automation and CI/CD pipelines

**Examples:**
```bash
# Execute SQL query
databricks sql execute --sql "SELECT * FROM catalog.schema.table"

# List and manage jobs
databricks jobs list --profile biprod
databricks jobs run-now --job-id 12345

# Export notebook for version control
databricks workspace export /notebook.py output.py

# Manage clusters
databricks clusters list
databricks clusters start --cluster-id abc-123
```

**Best For:**
- DevOps and automation workflows
- Job scheduling and orchestration
- Notebook version control
- Production deployments
- Multi-workspace management

### MCP Strengths (Managed)

**Interactive Data Exploration:**
- Natural language queries against Unity Catalog
- Automatic resource discovery
- Genie space conversations
- Vector search integration
- Function signature access

**Examples:**
```
"List all tables in the analytics catalog"
"Show me the schema for the customers table"
"Query sales data grouped by region for Q4"
"What functions are available in the finance schema?"
"Search for customer support tickets about billing"
```

**Best For:**
- Ad-hoc data analysis
- Unity Catalog exploration
- Genie-powered insights
- Conversational BI workflows
- Claude Desktop integration

### MCP Strengths (databrickslabs - Experimental)

**Developer Testing:**
- Local Unity Catalog access
- Development workflows
- Testing MCP concepts
- Learning and experimentation

**Best For:**
- Development environments
- Testing before managed MCP adoption
- Learning MCP capabilities
- Custom integrations

---

## Configuration & Permissions

### Databricks CLI

**Configuration:**
- Stored in `~/.databrickscfg`
- Profile-based for multiple workspaces
- OAuth or Personal Access Token auth

**Permissions:**
- Uses Databricks role permissions
- Workspace-level access control
- No additional permission layers

**Example:**
```ini
[biprod]
host = https://prod.cloud.databricks.com
auth_type = oauth

[bidev]
host = https://dev.cloud.databricks.com
token = dapi_dev_token
```

### Managed MCP

**Configuration:**
- No local configuration needed
- Server URL points to workspace resources
- Integrated authentication

**Permissions:**
- Unity Catalog permissions enforced
- Automatic resource filtering
- Workspace-integrated access control

**Example:**
```
https://workspace.cloud.databricks.com/api/2.0/mcp/uc-functions/catalog/schema
```

### databrickslabs MCP

**Configuration:**
- Manual setup via `uv` and repository
- Schema-level configuration
- PAT authentication only

**Permissions:**
- Unity Catalog permissions
- Schema-specific access control
- Manual configuration via flags

**Example:**
```bash
claude mcp add databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://workspace.cloud.databricks.com \
  --token dapi_token \
  -s catalog.schema
```

---

## Context & Resource Considerations

### CLI

**Resource Usage:**
- Minimal Claude context usage
- Results returned as command output
- ~100-500 tokens for typical responses
- Suitable for large query results
- No inherent size limits

**Output Handling:**
- Direct to stdout
- Can pipe to files or other commands
- JSON formatting available

### MCP (Both Types)

**Resource Usage:**
- Data loaded into Claude's context
- Unity Catalog metadata in context
- Variable token usage based on query complexity
- Best for exploratory queries

**Response Limits:**
- Managed: Optimized by Databricks
- databrickslabs: Community implementation limits

---

## Workflow Integration

Use **both** together for optimal results:

| Phase | Tool | Purpose |
|-------|------|---------|
| **Explore** | MCP | Discover Unity Catalog resources, understand schema |
| **Prototype** | MCP | Interactive queries, test logic conversationally |
| **Productionize** | CLI | Create jobs, schedule workflows, automate |
| **Deploy** | CLI | Manage notebooks, configure clusters, release |
| **Monitor** | CLI | Check job status, review logs, troubleshoot |

**Common Patterns:**

1. **Data Analysis Workflow:**
   - Explore with MCP → Refine queries → Execute production queries with CLI

2. **Notebook Development:**
   - Prototype with Claude + MCP → Export with CLI → Deploy to production

3. **Job Creation:**
   - Design logic conversationally → Create job config → Deploy via CLI

---

## Authentication Comparison

| Method | CLI | Managed MCP | databrickslabs MCP |
|--------|-----|-------------|-------------------|
| **OAuth** | ✅ Recommended | ✅ Integrated | ❌ Not supported |
| **Personal Access Token** | ✅ Supported | ⚠️ Workspace uses | ✅ Required |
| **SSO Integration** | ⚠️ Via OAuth | ✅ Automatic | ❌ Not supported |
| **Token Rotation** | Manual | Automatic | Manual |
| **Multi-Workspace** | ✅ Profiles | ✅ Multiple URLs | ⚠️ Separate configs |

---

## Production Readiness

### Databricks CLI

**Status:** ✅ Production-ready
- Official Databricks support
- Regular updates and maintenance
- Stable API
- Comprehensive documentation
- Used in enterprise CI/CD

**Use For:**
- Production automation
- Critical workflows
- Enterprise deployments

### Managed MCP

**Status:** ✅ Production-ready
- Fully supported with SLAs
- Hosted by Databricks
- Automatic updates
- Enterprise-grade security

**Use For:**
- Interactive BI workflows
- Unity Catalog exploration
- Genie space integration
- Claude Desktop/Code usage

### databrickslabs MCP

**Status:** ⚠️ Experimental
- Community-maintained
- No official support or SLAs
- Breaking changes possible
- Active development

**Use For:**
- Development environments only
- Learning and testing
- Proof of concept work

---

## Setup Time & Complexity

| Tool | Setup Time | Complexity | Maintenance |
|------|------------|------------|-------------|
| **CLI** | 5 minutes | Low | Minimal - update via brew |
| **Managed MCP** | Immediate | Very Low | None - managed by Databricks |
| **databrickslabs MCP** | 15 minutes | High | Regular updates needed |

---

## Feature Comparison Matrix

### SQL & Data Operations

| Feature | CLI | Managed MCP | databrickslabs MCP |
|---------|-----|-------------|-------------------|
| Execute SQL | ✅ | ✅ | ✅ |
| List tables | ✅ Manual | ✅ Auto-discovery | ✅ Schema-level |
| View schemas | ✅ Manual | ✅ Auto-discovery | ✅ Schema-level |
| Large queries | ✅ Optimized | ⚠️ Context limits | ⚠️ Context limits |
| Query history | ⚠️ Via workspace | ❌ | ❌ |

### Workspace Management

| Feature | CLI | Managed MCP | databrickslabs MCP |
|---------|-----|-------------|-------------------|
| List workspaces | ✅ | ❌ | ❌ |
| Export notebooks | ✅ | ❌ | ❌ |
| Import notebooks | ✅ | ❌ | ❌ |
| DBFS operations | ✅ | ❌ | ❌ |

### Job & Cluster Management

| Feature | CLI | Managed MCP | databrickslabs MCP |
|---------|-----|-------------|-------------------|
| List jobs | ✅ | ❌ | ❌ |
| Create jobs | ✅ | ❌ | ❌ |
| Run jobs | ✅ | ❌ | ❌ |
| Manage clusters | ✅ | ❌ | ❌ |
| View logs | ✅ | ❌ | ❌ |

### Unity Catalog & AI

| Feature | CLI | Managed MCP | databrickslabs MCP |
|---------|-----|-------------|-------------------|
| UC Functions | ⚠️ Manual | ✅ Auto-discovery | ⚠️ Basic |
| Vector Search | ⚠️ SQL only | ✅ Integrated | ❌ |
| Genie Spaces | ❌ | ✅ Native | ⚠️ Basic |
| Conversational BI | ❌ | ✅ | ⚠️ Limited |

---

## Cost Considerations

### CLI
- **License:** Free
- **Compute:** Standard Databricks pricing for queries
- **Storage:** Standard workspace storage rates

### Managed MCP
- **License:** Included with workspace
- **Compute:** Standard SQL warehouse pricing
- **MCP Hosting:** No additional cost

### databrickslabs MCP
- **License:** Open source (free)
- **Compute:** Standard pricing for queries
- **Hosting:** Self-hosted (local or Databricks Apps)

---

## Summary

### When to Use CLI

✅ **Choose CLI for:**
- Workspace and job management
- Production automation and CI/CD
- Notebook version control
- Cluster operations
- DBFS file management
- Multi-workspace administration
- Scheduled workflows

**Key Advantage:** Complete Databricks platform control

### When to Use Managed MCP

✅ **Choose Managed MCP for:**
- Interactive Unity Catalog exploration
- Genie space conversations
- Natural language data queries
- Claude Desktop integration
- Vector search operations
- Production BI workflows with support

**Key Advantage:** Zero-setup Unity Catalog access with official support

### When to Use databrickslabs MCP

⚠️ **Choose databrickslabs MCP for:**
- Development environments
- Testing MCP capabilities
- Learning Unity Catalog MCP
- Situations where managed MCP unavailable

**Key Advantage:** Experimental access to community features

### Best Practice: Use Both

**Recommended Workflow:**
1. **Setup CLI first** (required for comprehensive Databricks management)
2. **Add Managed MCP** for interactive data exploration (if Unity Catalog enabled)
3. **Use CLI for production**, MCP for exploration
4. **Automate with CLI**, explore with MCP

---

## Migration Path

**From databrickslabs MCP to Managed MCP:**
1. Verify Unity Catalog workspace
2. Configure managed MCP server URLs
3. Remove databrickslabs MCP configuration
4. Test with existing queries

**Benefits:**
- Official support and SLAs
- Automatic updates
- Better performance
- Simplified configuration

---

## Setup Guides

- **[Databricks CLI Setup](../instructions/DATABRICKS_CLI_SETUP.md)** - Complete installation guide
- **[Databricks MCP Setup](../instructions/DATABRICKS_MCP_SETUP.md)** - All three MCP options
- **[Troubleshooting](../instructions/TROUBLESHOOTING.md)** - Common issues and solutions

---

**Resources:**
- Databricks CLI Docs: https://docs.databricks.com/dev-tools/cli/
- Managed MCP Docs: https://docs.databricks.com/mcp/
- databrickslabs MCP: https://github.com/databrickslabs/mcp
