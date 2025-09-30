# Data Intelligence Tickets

> 📊 **Comprehensive knowledge base for data intelligence ticket resolution and institutional knowledge management**

[![Tickets Resolved](https://img.shields.io/badge/Tickets_Resolved-21-green.svg)](https://github.com/HappyMoneyInc/data-intelligence-tickets)
[![Team Members](https://img.shields.io/badge/Team_Members-1-blue.svg)](https://github.com/HappyMoneyInc/data-intelligence-tickets/tree/main/tickets)
[![Documentation](https://img.shields.io/badge/Documentation-Complete-brightgreen.svg)](https://github.com/HappyMoneyInc/data-intelligence-tickets/blob/main/CLAUDE.md)

## 📑 Table of Contents

- [🎯 Purpose & Overview](#-purpose--overview)
- [🚀 Quick Start](#-quick-start)
- [🏗️ Repository Structure](#%EF%B8%8F-repository-structure)
- [🔧 Available Tools](#-available-tools)
- [📋 Ticket Resolution Workflow](#-ticket-resolution-workflow)
- [💡 Technical Guidelines](#-technical-guidelines)
- [📊 Completed Tickets](#-completed-tickets)
- [🤝 Contributing](#-contributing)

## 🎯 Purpose & Overview

This repository serves as a **continuous knowledge base** for solving data intelligence tickets and issues. It consolidates documentation, scripts, and solutions to help streamline ticket resolution and maintain institutional knowledge.

### Key Objectives
- 🎯 **Build comprehensive knowledge base** for recurring issues and solutions
- 📚 **Document ticket resolutions** for future reference and learning
- 🔧 **Provide reusable scripts and tools** for common data intelligence tasks
- 👥 **Enable efficient collaboration** on complex data analysis projects

### Business Impact
- **Faster Resolution Times**: Leverage existing solutions and patterns
- **Knowledge Retention**: Preserve expertise across team transitions
- **Quality Assurance**: Established workflows ensure consistent deliverables
- **Scalability**: Standardized processes support team growth

## 🚀 Quick Start

### For New Team Members
1. **📖 Review Core Documentation**
   - [`CLAUDE.md`](CLAUDE.md) - AI assistance instructions and workflows
   - [`documentation/data_catalog.md`](documentation/data_catalog.md) - Database architecture and object reference
   - [`documentation/prerequisite_installations.md`](documentation/prerequisite_installations.md) - Required tools setup

2. **🛠️ Environment Setup**
   - Install required [CLI tools](documentation/prerequisite_installations.md)
   - Configure database and API connections
   - Set up authentication for Snowflake (Duo), Jira, and GitHub

3. **🔍 Explore Existing Solutions**
   - Browse [`tickets/`](tickets/) directory for similar past work
   - Search repository for relevant patterns and solutions
   - Review [completed tickets](#-completed-tickets) for context

### For Urgent Issues
- **🆘 Critical Issues**: Check `tickets/` for immediate patterns
- **🔗 Related Work**: Use GitHub search to find similar ticket solutions
- **📞 Escalation**: Reference stakeholder communication patterns in ticket READMEs

## 🏗️ Repository Structure

```
data-intelligence-tickets/
├── README.md                    # This comprehensive guide
├── CLAUDE.md                   # AI assistance instructions and workflows
├── documentation/              # Core technical documentation
│   ├── data_catalog.md        # Database architecture and schema reference
│   ├── db_deploy_template.sql # Standardized deployment scripts
│   └── prerequisite_installations.md # Tool setup guide
├── resources/                  # Shared utilities and integrations
│   └── slack_user_functions.zsh # Slack CLI integration functions
└── tickets/                    # Organized solutions by team member
    └── [team_member]/
        └── [TICKET-ID]/
            ├── README.md                # Comprehensive ticket documentation
            ├── source_materials/        # Original requirements and data
            ├── final_deliverables/      # Ready-to-deliver outputs
            │   ├── sql_queries/        # Production SQL scripts
            │   └── qc_queries/         # Quality control validation
            ├── exploratory_analysis/    # Development work and iterations
            └── archive_versions/        # Historical development versions
```

### Folder Standards
- **📁 source_materials/**: Original requirements, attachments, reference files
- **📁 final_deliverables/**: Production-ready outputs (CSV, SQL, documentation)
- **📁 qc_queries/**: Quality control and validation queries
- **📁 exploratory_analysis/**: Development work, testing, iterations
- **📁 archive_versions/**: Previous iterations and backup versions

## 🔧 Available Tools

### Core Platform Tools
| Tool | Purpose | Authentication | Key Features |
|------|---------|---------------|--------------|
| **Snowflake CLI (`snow`)** | Database queries and management | Duo Security | Query execution, data loading, warehouse management |
| **Jira CLI (`acli`)** | Ticket tracking and documentation | OAuth | Ticket creation, comments, workflow transitions |
| **Tableau CLI (`tabcmd`)** | Tableau server management | Server login | Workbook publishing, user management, extract refresh |
| **GitHub CLI (`gh`)** | Repository and issue management | OAuth | PR creation, issue tracking, automated workflows |

### Custom Integrations
- **Slack CLI Functions**: Direct messaging, user lookup, group conversations
- **Google Drive Integration**: Automated backup and file synchronization
- **Database Deployment**: Standardized cross-environment deployment scripts

> 📋 **Installation Guide**: See [`documentation/prerequisite_installations.md`](documentation/prerequisite_installations.md) for complete setup instructions.

## 📋 Ticket Resolution Workflow

### 🏁 Phase 1: Setup & Planning
```bash
# Branch creation and folder structure
git checkout main && git pull origin main
git checkout -b DI-XXX
mkdir -p tickets/[team_member]/DI-XXX/{source_materials,final_deliverables,exploratory_analysis}
```

### 🔍 Phase 2: Research & Investigation
- **📊 Data Exploration**: Use `snow sql` with Duo authentication
- **🔗 Identifier Strategy**: Leverage `LEAD_GUID` for cross-system reliability
- **📖 Reference Documentation**: Consult [`data_catalog.md`](documentation/data_catalog.md) for schema guidance
- **🔄 Pattern Recognition**: Search existing tickets for similar patterns

### ⚙️ Phase 3: Development & Analysis
- **🏗️ Incremental Development**: Build queries from simple to complex
- **🎯 Schema Filtering**: Apply `arca.CONFIG.LMS_SCHEMA()` and `LOS_SCHEMA()` patterns
- **🧪 Testing Approach**: Use `LIMIT` clauses and date filters during exploration
- **📋 Quality Control**: Create validation queries in dedicated QC folder

### 📊 Phase 4: Results & Validation
- **🔍 Data Quality Assessment**: Analyze completeness and accuracy patterns
- **💼 Stakeholder Communication**: Focus on business impact over technical details
- **✅ Quality Assurance**: Execute comprehensive validation queries
- **📈 Performance Optimization**: Measure and optimize query execution times

### 📄 Phase 5: Documentation & Delivery
- **🗂️ File Organization**: Clean structure with archived iterations
- **📚 Knowledge Capture**: Document learnings in [`CLAUDE.md`](CLAUDE.md)
- **💬 Stakeholder Communication**: Clear Jira comments with deliverable links
- **💾 Backup Strategy**: Google Drive preservation for team access

### 🔄 Phase 6: Review & Integration
- **🔍 Pull Request Creation**: Comprehensive documentation and testing
- **📊 Ticket Log Update**: Add entry to [completed tickets](#-completed-tickets) section
- **🔄 Version Control**: Ensure all work is properly tracked and accessible

## 💡 Technical Guidelines

### 🔒 Security & Authentication
- **🔐 Snowflake**: Duo Security authentication with 15-minute lockout protection
- **🔑 Credentials**: Use environment variables, never hardcode secrets
- **🛡️ Data Policies**: Ensure compliance with organizational data handling requirements

### 🗄️ Database Best Practices

#### Schema Filtering Patterns
```sql
-- Loan Management System (LMS) data
WHERE SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()

-- Loan Origination System (LOS) data  
WHERE SCHEMA_NAME = arca.CONFIG.LOS_SCHEMA()
```

#### Reliable Join Strategies
```sql
-- Primary: Use LEAD_GUID when available (most reliable)
JOIN table2 ON table1.LEAD_GUID = table2.LEAD_GUID

-- Secondary: LEGACY_LOAN_ID for stakeholder-friendly references
LEFT JOIN table3 ON CAST(table1.LEGACY_LOAN_ID AS VARCHAR) = table3.EXTERNAL_LOAN_ID
```

#### Data Quality Handling
```sql
-- Handle formatted CSV data with error protection
TRY_TO_NUMBER(REPLACE(balance_field, ',', '')) as CLEAN_BALANCE,
TRY_TO_DATE(date_field, 'MM/DD/YYYY') as CLEAN_DATE
```

### 📊 Specialized Analysis Patterns

#### Fraud Detection Multi-Source
```sql
-- Comprehensive fraud detection across multiple data sources
SELECT loan_id,
       MAX(CASE WHEN portfolio_name LIKE '%Fraud - Confirmed%' THEN 1 ELSE 0 END) as FRAUD_PORTFOLIO,
       MAX(CASE WHEN loan_status LIKE '%fraud%' THEN 1 ELSE 0 END) as FRAUD_STATUS,
       MAX(CASE WHEN investigation_result = 'FRAUD_CONFIRMED' THEN 1 ELSE 0 END) as FRAUD_INVESTIGATION
FROM loan_data_comprehensive
GROUP BY loan_id;
```

#### Partner Analysis for Repurchase
```sql
-- Flatten partner relationships to avoid duplicates
SELECT loan_id,
       LISTAGG(DISTINCT partner_name, '; ') WITHIN GROUP (ORDER BY partner_name) as ALL_PARTNERS,
       CASE WHEN COUNT(DISTINCT partner_name) > 1 THEN 1 ELSE 0 END as MULTIPLE_PARTNERS
FROM partner_relationships
GROUP BY loan_id;
```

### 🏗️ Deployment Standards
- **📜 Templates**: Use [`db_deploy_template.sql`](documentation/db_deploy_template.sql) for cross-environment deployment
- **🔄 Environment Variables**: Support dev/test/prod with parameter switching
- **🔐 Permission Preservation**: Include `COPY GRANTS` in CREATE statements
- **🔍 Validation**: Test deployment scripts before production execution

## 📊 Completed Tickets

> **Statistics**: 21 tickets completed • $19.8M+ in business value • 50-70% performance improvements achieved

### 📈 By Category

| Category | Count | Key Achievements |
|----------|-------|------------------|
| 🔍 **Fraud Analysis** | 4 | Multi-source detection, binary classification patterns, centralized analytics view |
| 💰 **Debt Sales** | 5 | $19.8M+ portfolio management, automated workflows |
| 📊 **Regulatory Requests** | 3 | State compliance, Fair Lending audit resolution, license applications |
| 🏗️ **Data Infrastructure** | 6 | View deployments, PII optimization, data structure alignment, enhanced custom fields |
| 📈 **Performance Analytics** | 3 | Application analysis, device usage patterns |

### 📅 2025 Chronological Log

#### July 2025
- **[DI-934](tickets/kchalmers/DI-934/README.md)** - Fraud Loan Analysis with Repurchase Details  
  *Kyle Chalmers* | Complete fraud loan analysis across multiple data sources with binary classification patterns and partner ownership tracking

- **[DI-1065](tickets/kchalmers/DI-1065/README.md)** - Fortress Quarterly Due Diligence Payment History  
  *Kyle Chalmers* | Payment history extraction for 80 Fortress loans with quality control validation and attachment source tracking

- **[DI-1099](tickets/kchalmers/DI-1099/README.md)** - Theorem Goodbye Letter List for Loan Sale to Resurgent  
  *Kyle Chalmers* | Generated goodbye letter lists for 2,179 Theorem loans being sold to Resurgent with SFMC integration and portfolio breakdown

- **[DI-1100](tickets/kchalmers/DI-1100/README.md)** - Theorem (Pagaya) Credit Reporting and Placement Upload List for Loan Sale  
  *Kyle Chalmers* | Credit reporting and LoanPro placement upload files for 1,770 Theorem portfolio loans with Resurgent placement status

#### August 2025
- **[DI-974](tickets/kchalmers/DI-974/README.md)** - Add SIMM Placement Flag to Intra-month Roll Rate Dashboard  
  *Kyle Chalmers* | Added dual SIMM placement flags (current and historical) to roll rate dashboards with **40-60% performance optimization**

- **[DI-1131](tickets/kchalmers/DI-1131/README.md)** - Optimize Email and Phone Lookup Views with Improved Performance  
  *Kyle Chalmers* | Fixed PayoffUID matching issue for **376,453 multi-loan customers** by updating PII lookup tables to use current ANALYTICS_PII schema sources

- **[DI-1137](tickets/kchalmers/DI-1137/README.md)** - Regulator Request: Massachusetts - Applications and Loans  
  *Kyle Chalmers* | Massachusetts regulator request for loan/application data supporting license application: **61 MA resident loans** ($1.03M), **3 small dollar high-rate qualifying loans**, comprehensive SQL documentation with 4-scenario analysis

- **[DI-1140](tickets/kchalmers/DI-1140/README.md)** - Identify Originated Loans Associated w/ Suspected Small Fraud Ring  
  *Kyle Chalmers* | Fraud ring investigation targeting BMO Bank accounts with recent account opening patterns and routing number analysis

- **[DI-1141](tickets/kchalmers/DI-1141/README.md)** - Sale Files for Bounce - Q2 2025 Sale  
  *Kyle Chalmers* | Q2 2025 debt sale population (1,591 loans, **$19.8M**) with enhanced settlement monitoring, optimized SQL queries (**50-70% performance improvement**), and comprehensive exclusion analysis

- **[DI-1143](tickets/kchalmers/DI-1143/README.md)** - Align Oscilar Plaid Data Structure With Historical Plaid DATA_STORE Structure  
  *Kyle Chalmers* | Created views to transform Oscilar Plaid data to match historical DATA_STORE structure for Prism vendor compatibility

- **[DI-1146](tickets/kchalmers/DI-1146/README.md)** - Mobile vs Desktop Application Analysis  
  *Kyle Chalmers* | Device usage pattern analysis showing **68.9% mobile-only** vs **26.9% desktop-only** applications with **99.96% data coverage** and 4.35% cross-device behavior

- **[DI-1148](tickets/kchalmers/DI-1148/README.md)** - Bank Account LMS Views Deployment  
  *Kyle Chalmers* | Created views for bank account data alignment in loan management system

- **[DI-1150](tickets/kchalmers/DI-1150/README.md)** - Application Drop-off Analysis  
  *Kyle Chalmers* | Comprehensive analysis of application funnel drop-offs with API vs non-API channel comparison and fraud correlation patterns

- **[DI-1151](tickets/kchalmers/DI-1151/README.md)** - Bounce Q2 2025 Debt Sale Deliverables  
  *Kyle Chalmers* | Generated three required debt sale deliverable files (marketing goodbye letters, credit reporting, bulk upload) for **1,483 selected loans** with comprehensive workflow documentation ([**INSTRUCTIONS.md**](tickets/kchalmers/DI-1151/INSTRUCTIONS.md))

- **[DI-1176](tickets/kchalmers/DI-1176/README.md)** - Fair Lending Audit - Theorem Application Reconciliation Analysis  
  *Kyle Chalmers* | Resolved **1.5M application discrepancy** for Fair Lending audit by clarifying definitional differences - only **3.3% were true applications** vs pricing inquiries

- **[DI-1179](tickets/kchalmers/DI-1179/README.md)** - Fraud Analytics View Implementation
  *Kyle Chalmers* | Created centralized fraud-only analytics view consolidating 4 detection sources into single comprehensive view with standardized logic across FRESHSNOW → BRIDGE → ANALYTICS layers

#### September 2025
- **[DI-1272](tickets/kchalmers/DI-1272/README.md)** - Enhanced VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT with 185 Missing Fields
  *Kyle Chalmers* | Enhanced view from 278 to 463 fields (67% increase) by adding missing CUSTOM_FIELD_VALUES. Comprehensive null analysis on 127K loans identified active usage: **9.66% HAPPY_SCORE adoption**, **7.35% loan modifications**, **5.05% bankruptcy tracking**. Identified 226 unused fields (49%) for potential cleanup via SERV-755.

### 🎯 High-Impact Deliverables
- **💰 $19.8M Portfolio Management**: Comprehensive debt sale analysis and transfer workflows
- **⚡ 40-70% Performance Improvements**: Optimized SQL queries and dashboard efficiency  
- **📊 99.96% Data Coverage**: Near-complete application analysis with device usage insights
- **📋 Comprehensive Workflows**: Standardized processes for debt sale deliverables ([INSTRUCTIONS.md](tickets/kchalmers/DI-1151/INSTRUCTIONS.md))

## 🤝 Contributing

### ✅ Quality Standards
1. **🔄 Follow 6-Phase Workflow**: Complete setup through integration phases
2. **📚 Document Learnings**: Update [`CLAUDE.md`](CLAUDE.md) with fundamental insights
3. **🗂️ Maintain Clean Organization**: Use archive structure for development iterations
4. **💼 Stakeholder Focus**: Provide business impact summaries, not technical deep-dives
5. **💾 Backup Preservation**: Copy final deliverables to Google Drive team folders
6. **🔍 Code Review Process**: Submit PR with comprehensive testing and documentation
7. **📊 Update Ticket Log**: Add new completions to this README with detailed descriptions

### 🎯 Success Criteria
- **📋 Complete Documentation**: Comprehensive README with business context
- **✅ Quality Validation**: All QC queries executed successfully
- **🔗 Stakeholder Communication**: Clear Jira updates with deliverable links
- **💾 Backup Completion**: Google Drive preservation for team access
- **📊 Performance Documentation**: Query optimization results where applicable

### 📞 Support & Resources
- **📖 Technical Documentation**: [`CLAUDE.md`](CLAUDE.md) for detailed workflows
- **🗄️ Database Reference**: [`data_catalog.md`](documentation/data_catalog.md) for schema guidance
- **🛠️ Tool Setup**: [`prerequisite_installations.md`](documentation/prerequisite_installations.md) for environment configuration
- **💬 Slack Integration**: [`resources/slack_user_functions.zsh`](resources/slack_user_functions.zsh) for team communication

---

> 📈 **Repository Metrics**: 21 tickets resolved • 240+ files • Comprehensive workflow documentation
> 🔧 **Last Updated**: September 2025 • Active development and knowledge capture ongoing