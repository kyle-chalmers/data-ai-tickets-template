# Data & AI Tickets Template

> 📺 **Reference repository for the [Kyle Chalmers Data & AI YouTube channel](https://youtube.com/@kylechalmersdataai)**

Reference repository for the Kyle Chalmers Data & AI YouTube channel. Provides structured templates for managing data tasks with quality-first SQL development, standardized ticket workflows, automated QC validation, and multi-layer architecture patterns. Use as a foundation for reproducible analytics work.

## 🎯 What This Repository Is

This repository serves **two purposes**:

1. **📺 Video Demonstrations** - Contains real examples of data analysis work featured in YouTube videos, showing practical applications of:
   - AI-assisted data analysis with Claude Code
   - Snowflake data warehouse development
   - Quality-first SQL development practices
   - Data ticket resolution workflows

2. **📋 Template for Your Own Work** - Provides a structured framework you can adopt for your own data analysis projects:
   - Standardized folder structures
   - Quality control patterns
   - Documentation templates
   - AI assistant instructions (CLAUDE.md)

## 📂 What's Inside

### Video Work Examples
The `videos/` folder contains complete examples from YouTube videos:
- **Claude Code Overview** - Complete guide to Claude Code for data teams including:
  - Installation, setup, and modes
  - Compaction and context management
  - Custom commands and agents
  - Settings and configuration
- **Integrating AI and Snowflake** - Using Claude Code with Snowflake MCP server for data analysis
- **Integrating Claude and Databricks** - Databricks CLI workflows including:
  - Unity Catalog exploration
  - Notebook creation and job scheduling
  - Job troubleshooting and error resolution
- **Integrating Jira and Ticket Taking** - Atlassian integration including:
  - Atlassian CLI setup and configuration
  - Atlassian MCP server setup
  - Ticket workflow automation

### Template Materials
Core template files you can adapt for your own projects:

- **`CLAUDE.md`** - Comprehensive AI assistant instructions for data analysis work
- **`documentation/`** - Template documentation structures:
  - `data_catalog.md` - Schema documentation template
  - `data_business_context.md` - Business context documentation template
  - `helpful_mac_installations.md` - CLI tool setup guide
- **`.claude/agents/`** - Custom Claude Code agents for specialized tasks:
  - `code-review-agent.md` - SQL, Python, and notebook review
  - `sql-quality-agent.md` - Query optimization and best practices
  - `qc-validator-agent.md` - Quality control validation
  - `docs-review-agent.md` - Video documentation review, URL validation, and indexing

### Folder Structure Template
```
your-project/
├── README.md                    # Project overview and documentation
├── CLAUDE.md                   # AI assistant instructions
├── documentation/              # Technical documentation
│   ├── data_catalog.md        # Database schema reference
│   └── data_business_context.md # Business definitions
└── tickets/                    # Organized work by ticket/task
    └── [team_member]/
        └── [TICKET-ID]/
            ├── README.md                # Task documentation
            ├── source_materials/        # Original requirements
            ├── final_deliverables/      # Production outputs
            │   ├── sql_queries/        # Final SQL scripts
            │   └── qc_queries/         # Quality validation
            └── exploratory_analysis/    # Development work
```

## 🚀 How to Use This Template

### For Learning
1. Watch the corresponding YouTube videos for context
2. Explore the `videos/` folder to see real implementations
3. Study the quality control patterns and documentation approaches
4. Review `CLAUDE.md` to understand AI-assisted workflows

### For Your Own Projects
1. **Fork or clone** this repository
2. **Customize CLAUDE.md** with your specific:
   - Database architecture
   - Business context
   - Team workflows
   - Tool configurations
3. **Adapt folder structures** to match your needs
4. **Use as foundation** for your data analysis ticket system

## 🛠️ Key Tools Demonstrated

This template showcases integration with:
- **Snowflake** - Cloud data warehouse and SQL development
- **Databricks** - Unified analytics platform and job orchestration
- **Claude Code** - AI-assisted coding and analysis
- **Snowflake MCP Server** - Model Context Protocol for database integration
- **Databricks CLI** - Workspace management, job scheduling, and troubleshooting
- **Git workflows** - Version control and collaboration patterns
- **Quality control frameworks** - Automated validation approaches

## 📺 Related Videos

Check the [Kyle Chalmers Data & AI YouTube channel](https://youtube.com/@kylechalmersdataai) for videos demonstrating these workflows:

| Video | Description |
|-------|-------------|
| [If You Are in Data and Want to Leverage AI, this is Made for You](https://www.youtube.com/watch?v=NDR0tiJWWEA) | Introduction to the repository and AI-assisted data workflows |
| [The AI Integration Every Data Professional Needs](https://www.youtube.com/watch?v=q1y7M5mZkkE) | Claude Code + Snowflake workflow demo |
| [Claude Code Makes Databricks Easy](https://www.youtube.com/watch?v=5_q7j-k8DbM) | Jobs, Notebooks, SQL & Unity Catalog via CLI |
| [How to SUCCESSFULLY Integrate Claude in Your Jira Workflow](https://www.youtube.com/watch?v=WRvgMzYaIVo) | Atlassian CLI and MCP integration guide |

## 💡 Key Concepts

### Quality-First Development
- **QC validation** as core requirement, not afterthought
- Automated quality checks in dedicated folders
- Clear documentation of assumptions and business logic

### Structured Workflows
- Standardized folder organization for reproducibility
- Numbered files for logical review progression
- Comprehensive documentation templates

### AI-Assisted Analysis
- Detailed AI assistant instructions in CLAUDE.md
- Integration patterns with data tools and CLIs
- Automated quality validation approaches

## 🤝 Contributing

This is a personal reference repository for YouTube content. However, if you:
- Find issues with the templates
- Have suggestions for improvements
- Want to share how you've adapted it

Feel free to open an issue or reach out!

## 📝 License

This template is provided as-is for educational and reference purposes. Adapt freely for your own data analysis work.

---

**📺 Subscribe to [Kyle Chalmers Data & AI](https://youtube.com/@kylechalmersdataai) for more data engineering and AI content!**
