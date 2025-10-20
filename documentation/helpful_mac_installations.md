# Prerequisite Installation Guide

This guide outlines the recommended tools and CLI utilities for optimal data analysis work with Claude Code assistant.

## Essential CLI Tools

### macOS (via Homebrew)

First, ensure Homebrew is installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install essential tools:
```bash
# Core utilities
brew install tree          # Directory visualization
brew install jq            # JSON processing
brew install bat           # Better 'cat' with syntax highlighting
brew install ripgrep       # Fast text search (rg command)
brew install fd            # Better 'find' command
brew install fzf           # Fuzzy finder for commands and files
brew install htop          # Better process viewer (requires sudo)

# Database tools
brew install postgresql    # psql command for database connections
brew install mysql-client  # mysql command line client

# Data science and analysis tools ✅
brew install csvkit        # CSV manipulation tools
brew install duckdb        # Fast analytical SQL database
brew install miller        # Data transformation tool
brew install yq            # YAML/JSON processor
brew install xsv           # Fast CSV toolkit  
brew install hyperfine     # Benchmarking tool

# Development tools
brew install git           # Version control (usually pre-installed)
brew install gh            # GitHub CLI
brew install curl          # HTTP requests (usually pre-installed)
brew install wget          # File downloads
```

### Windows (via Package Managers)

#### Option 1: Chocolatey
```powershell
# Install Chocolatey first (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install tools
choco install tree
choco install jq
choco install ripgrep
choco install fd
choco install fzf
choco install git
choco install gh
choco install curl
choco install wget
```

#### Option 2: Windows Subsystem for Linux (WSL)
```bash
# Use Ubuntu/Debian commands in WSL
sudo apt update
sudo apt install tree jq ripgrep fd-find fzf git curl wget
```

#### Option 3: Scoop (Alternative Package Manager)
```powershell
# Install Scoop first
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install tools
scoop install tree
scoop install jq
scoop install ripgrep
scoop install fd
scoop install fzf
scoop install git
scoop install gh
```

## Tool Descriptions and Usage

### Core File Management
- **tree**: Displays directory structures in tree format
  ```bash
  tree /path/to/directory    # Show directory structure
  tree -L 2                  # Limit to 2 levels deep
  ```

- **fd**: Fast file finder, replacement for 'find'
  ```bash
  fd filename                # Find files by name
  fd -e sql                  # Find all .sql files
  ```

- **ripgrep (rg)**: Extremely fast text search
  ```bash
  rg "pattern" /path/        # Search for pattern in files
  rg -i "case-insensitive"   # Case insensitive search
  ```

### Data Processing
- **jq**: JSON processor for API responses and JSON files
  ```bash
  cat file.json | jq '.'     # Pretty print JSON
  echo '{"name":"John"}' | jq '.name'  # Extract field
  ```

- **bat**: Enhanced file viewer with syntax highlighting
  ```bash
  bat file.sql               # View SQL file with highlighting
  bat --style=plain file.txt # Plain output without line numbers
  ```

### Data Science and Analysis Tools ✅
- **csvkit**: Swiss army knife for CSV files
  ```bash
  csvstat data.csv           # Quick statistics
  csvsql --query "SELECT * FROM data WHERE amount > 100" data.csv
  csvcut -c name,amount data.csv  # Select columns
  ```

- **DuckDB**: Fast analytical SQL database
  ```bash
  duckdb -c "SELECT * FROM 'data.csv' WHERE amount > 1000"
  duckdb mydb.db             # Connect to persistent database
  ```

- **Miller (mlr)**: Data transformation tool
  ```bash
  mlr --csv cut -f name,amount data.csv        # Select fields
  mlr --csv stats1 -a mean,count -f amount data.csv  # Statistics
  ```

- **yq**: YAML/JSON processor
  ```bash
  yq '.field' config.yaml    # Extract YAML field
  yq -o json config.yaml     # Convert YAML to JSON
  ```

- **xsv**: Fast CSV toolkit
  ```bash
  xsv stats data.csv         # CSV statistics
  xsv search "pattern" data.csv  # Search CSV content
  ```

- **hyperfine**: Benchmarking tool
  ```bash
  hyperfine "snow sql -q 'SELECT COUNT(*) FROM table'"  # Benchmark queries
  hyperfine --warmup 3 "command"  # Multiple runs with warmup
  ```

### Interactive Tools
- **fzf**: Fuzzy finder for interactive selections
  ```bash
  git log --oneline | fzf    # Interactive commit selection
  history | fzf              # Search command history
  ```

- **htop**: Interactive process viewer
  ```bash
  sudo htop                  # View system processes (requires sudo on macOS)
  ```

## Database-Specific Tools

### Snowflake
- Snowflake CLI should be installed separately following Snowflake's documentation
- Requires separate authentication setup

### Tableau
- Tableau CLI (tabcmd) requires separate installation from Tableau
- Installation varies by Tableau version and deployment

## Shell Integration

### FZF Shell Integration (Recommended)
Add to your shell configuration file (`~/.zshrc` or `~/.bashrc`):
```bash
# FZF key bindings and fuzzy completion
eval "$(fzf --bash)"  # For bash
eval "$(fzf --zsh)"   # For zsh
```

### Aliases (Optional but Helpful)
Add these to your shell configuration:
```bash
# Better defaults
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='rg'
alias find='fd'
alias cat='bat'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline'
```

## Verification

Test your installation:
```bash
# Verify each tool is installed
tree --version
jq --version
rg --version
fd --version
fzf --version
bat --version

# Test basic functionality
echo '{"test": "value"}' | jq '.'
echo "test content" | rg "test"
fd README
```

## Troubleshooting

### macOS Issues
- If Homebrew commands fail, ensure Xcode Command Line Tools are installed:
  ```bash
  xcode-select --install
  ```

### Windows Issues
- For PowerShell execution policy errors, run as Administrator:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Path Issues
- Ensure tools are in your PATH by restarting your terminal or running:
  ```bash
  source ~/.zshrc    # or ~/.bashrc
  ```

## Additional Recommendations

### Text Editors
- **VS Code**: Excellent for SQL and JSON editing
- **Vim/Neovim**: Powerful terminal-based editing
- **Sublime Text**: Fast GUI editor

### Data Tools
- **DBeaver**: Universal database GUI client
- **DataGrip**: JetBrains database IDE
- **Tableplus**: Modern database client (macOS)

## Existing Installations (Already Available)

The following tools are already installed and have been essential for data analysis work:

### Database and API Tools
- **Snowflake CLI (`snow`)**: Primary database interface for querying data warehouses
  - Used for: Running SQL queries, managing Snowflake objects, data exploration
  - Authentication: Duo Security integration
  - Example: `snow sql -q "SELECT * FROM table" --format csv`

- **Atlassian CLI (`acli`)**: Jira and Confluence integration
  - Used for: Reading ticket details, updating tickets, workflow automation
  - Example: `acli jira workitem view TICKET-974`

- **Tableau CLI (`tabcmd`)**: Tableau Server/Cloud management
  - Used for: Publishing workbooks, managing users, refreshing extracts
  - Example: `tabcmd refreshextracts --workbook "Dashboard Name"`

- **GitHub CLI (`gh`)**: Git repository management
  - Used for: Creating pull requests, managing issues, repository operations
  - Example: `gh pr create --title "TICKET-974: Add Feature Flag"`

### Development Tools
- **Git**: Version control system
  - Used for: Branch management, commit tracking, collaboration
  - Essential for ticket workflow and code management

- **Python 3**: Programming language with data science libraries ✅
  - Used for: Data processing, analysis, automation scripts, data comparisons
  - **Installed Libraries**: pandas, numpy, matplotlib, seaborn, plotly, requests, openpyxl, xlsxwriter, beautifulsoup4, scipy, scikit-learn, snowflake-connector-python, sqlalchemy
  - **JupyterLab**: Interactive notebook environment for data analysis
  - Essential for data analysis tasks (preferred over bash commands for complex analysis)

### System Tools
- **curl**: HTTP client for API requests
  - Used for: Testing APIs, downloading data, webhook testing
  - Pre-installed on macOS

- **Standard Unix Tools**: grep, find, sed, awk, etc.
  - Used for: Text processing, file manipulation, data parsing
  - Enhanced by the new tools above (ripgrep replaces grep, fd replaces find)

### Why These Existing Tools Are Critical
1. **Snowflake CLI**: Core data access - without this, no database queries possible
2. **acli**: Ticket management - enables reading requirements and updating status
3. **gh**: Code management - essential for pull requests and repository operations
4. **Slack Functions**: Team communication - keeps stakeholders informed of progress
5. **Git**: Version control - fundamental for tracking changes and collaboration

### Integration Benefits
The new tools (jq, bat, fd, ripgrep, fzf, htop) complement these existing installations:
- **jq** processes JSON from APIs and Snowflake results
- **bat** displays SQL files and configs with syntax highlighting
- **ripgrep** searches through code repositories and documentation
- **fd** quickly finds files in ticket directories and codebases
- **fzf** provides interactive selection for git operations and file management
- **htop** monitors system resources during heavy Snowflake operations

This installation guide ensures you have all the tools needed for efficient data analysis work with the Claude Code assistant.