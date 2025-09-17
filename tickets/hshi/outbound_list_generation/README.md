# Outbound List Generation Documentation

## Overview

This documentation covers the complete outbound list generation system consisting of two primary Databricks jobs that run daily to create marketing and collections contact lists.

## System Architecture

**Primary Workflow**: `BI-2482_Outbound_List_Generation` (6:00 AM EST daily)
- **BI-2482**: Collections & Recovery campaigns (GR - Goal Realignment)
- **DI-986**: Marketing & Customer Engagement campaigns (Funnel)

## Quick Navigation

### Daily Operations
📋 **[Daily Operations Guide](daily_operations.md)**
- What happens each day (6:00 AM - 10:30 PM)
- Timeline and dependencies
- Morning checklist and monitoring

### Campaign Details
🎯 **[Campaign Types & Configuration](campaign_types.md)**
- BI-2482: Collections campaigns (DPD, SMS, Recovery)
- DI-986: Marketing campaigns (Email, Funnel, PIF)
- Suppression rules and business logic

### Technical Setup
⚙️ **[Technical Implementation](technical_setup.md)**
- Databricks workflow architecture
- Infrastructure and cluster configuration
- Data sources and output tables

### Genesis Integration
🔄 **[Genesis Integration Process](genesis_integration.md)**
- Daily import/export process (8:30 AM and 10:30 PM)
- Campaign configuration management
- Results processing and monitoring

### Issue Resolution
🚨 **[Troubleshooting Guide](troubleshooting.md)**
- Common failure scenarios and fixes
- Performance optimization
- Recovery procedures

### Administration
🛠️ **[Configuration Management](configuration_management.md)**
- Adding and retiring campaigns
- Updating suppression rules
- Change management process

## Quick Reference

**Workflow Schedule**: Daily at 6:00 AM EST (`14 0 6 * * ?`)
**Primary Output**: `CRON_STORE.RPT_OUTBOUND_LISTS`
**Monitoring Dashboard**: Tableau Genesis Integration Dashboard
**Notifications**: hshi@happymoney.com

---

*For questions: biteam@happymoney.com*
*Last Updated: September 2025*