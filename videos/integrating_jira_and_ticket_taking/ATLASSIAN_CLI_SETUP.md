# Atlassian CLI Setup

Quick setup guide for Atlassian CLI (acli) - enables command-line interaction with Jira, Confluence, and Rovo Dev.

**Official Documentation:** https://developer.atlassian.com/cloud/acli/guides/introduction/

## Quick Start (3 minutes)

```bash
# 1. Install via Homebrew
brew tap atlassian/homebrew-acli
brew install acli

# 2. Verify installation
acli --version
# Should show: acli version 1.3.5-stable (or later)

# 3. Authenticate (Choose Option A or B below)
```

**Time:** 3-5 minutes | **Installation:** Global (system-wide)

---

## Authentication Options

### Option A: Web Browser (OAuth) - Recommended

**Easiest method - uses browser for secure authentication:**

```bash
acli jira auth login --web
```

This will:
1. Open your browser
2. Prompt you to log in to Atlassian
3. Automatically configure authentication
4. No API token needed

### Option B: API Token

**For automation or when browser authentication isn't available:**

#### Step 1: Create API Token

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Give it a name (e.g., "CLI Access")
4. **Copy the token immediately** (you won't see it again)

#### Step 2: Save Token Securely

```bash
# Save token to a file (recommended)
echo "YOUR_API_TOKEN_HERE" > ~/.atlassian_token
chmod 600 ~/.atlassian_token
```

#### Step 3: Authenticate

```bash
# Using token file
acli jira auth login \
  --site "yourcompany.atlassian.net" \
  --email "your.email@company.com" \
  --token < ~/.atlassian_token

# OR using echo (less secure - visible in shell history)
echo "YOUR_TOKEN" | acli jira auth login \
  --site "yourcompany.atlassian.net" \
  --email "your.email@company.com" \
  --token
```

**Important:**
- API tokens expire in 1 year (created after Dec 15, 2024)
- Store tokens securely - never commit to git
- Tokens have same permissions as your user account

---

## Verify Authentication

Test your connection:

```bash
# View your Jira projects
acli jira project list

# View a specific ticket
acli jira workitem view TICKET-123

# List your assigned tickets
acli jira workitem list --assignee "$(acli jira auth whoami --json | jq -r '.email')"
```


---

## CLI vs. MCP: Which to Use?

For a detailed comparison of when to use Atlassian CLI vs. Atlassian MCP, see:
**[CLI vs. MCP Comparison Guide](./CLI_VS_MCP_COMPARISON.md)**

**Quick Summary:**
- **Use CLI** for automation, scripting, CI/CD, and bulk operations
- **Use MCP** for interactive exploration, natural language queries, and integrated analysis
- **Use both** for complete workflow coverage

---

## Additional Resources

**Official Documentation:**
- Introduction: https://developer.atlassian.com/cloud/acli/guides/introduction/
- Getting Started: https://developer.atlassian.com/cloud/acli/guides/how-to-get-started/
- Installation Guide: https://developer.atlassian.com/cloud/acli/guides/install-acli/
- Command Reference: https://developer.atlassian.com/cloud/acli/reference/commands/

**Authentication:**
- Create API Tokens: https://id.atlassian.com/manage-profile/security/api-tokens
- Manage API Tokens: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/

**Support:**
- Submit feedback: `acli feedback`
- GitHub Repository: https://github.com/atlassian/homebrew-acli
