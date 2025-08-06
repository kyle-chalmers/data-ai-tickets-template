# DI-1146: Mobile vs Desktop Application Analysis

## Overview
Analyze EVT_APPLICATION_ID_STR by operating system and device usage patterns to understand single vs multi-device application behavior and validate hypothesis about mobile conversion lag.

## Business Context
The team suspects mobile users may have lower conversion rates compared to desktop users. This analysis will provide data-driven insights into:
- Device switching behavior during applications
- Mobile vs desktop conversion patterns
- Cross-device user journey insights

## Data Source
- **Primary**: `FIVETRAN.FULLSTORY.SEGMENT_EVENT`
- **Key Fields**: `EVT_APPLICATION_ID_STR`, `PAGE_DEVICE`, `PAGE_OPERATING_SYSTEM`
- **Coverage**: Applications with FullStory tracking

## Deliverables
1. **Full Analysis Query**: Detailed breakdown by application ID showing device usage patterns
2. **Summary Query**: High-level metrics for business stakeholders
3. **Slack Update**: Key findings shared with team channel

## Key Findings

### Device Usage Patterns
- **93,530 applications** tracked with FullStory device data
- **99.96% match rate** to loan records (93,489 applications)
- **68.9% mobile-only** vs **26.9% desktop-only** usage
- **4.35% cross-device behavior** (3,618 applications)

### Application Pipeline Coverage  
- **79.0% submission rate** (73,863 of 93,489 matched apps)
- **13.6% offer selection rate** (12,687 apps)
- **6.5% origination rate** (6,044 apps)
- **0% approval records** (potential data pipeline gap)

### Business Implications
1. **Mobile-first strategy validated** - 69% mobile dominance
2. **Excellent data coverage** - 99.96% match enables robust analysis
3. **Cross-device users** represent small but potentially high-intent segment
4. **Data quality issue** - no approval dates recorded (investigate pipeline)

## Files
- `queries/1_full_analysis.sql` - Complete application device breakdown
- `queries/2_summary_analysis.sql` - Executive summary metrics
- `final_deliverables/device_analysis_results.csv` - Query results
- `slack_message.txt` - Prepared message for team channel

## Related
- **Jira**: [DI-1146](https://happymoneyinc.atlassian.net/browse/DI-1146)
- **Slack Channel**: [#data-intelligence](https://teamhappymoney.slack.com/archives/C08QT3MMDTM)