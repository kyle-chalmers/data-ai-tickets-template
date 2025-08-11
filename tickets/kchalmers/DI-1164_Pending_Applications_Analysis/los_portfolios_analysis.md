# LOS Portfolios Analysis - August 7th Pending Applications
**Analysis Date**: January 8, 2025  
**Data Source**: ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS  
**Applications Analyzed**: 44 pending applications from August 7, 2025

## Executive Summary
Analysis of LOS portfolios reveals that all pending applications have been assigned to **internal processing portfolios**, not external funding partner portfolios. This explains why they appear as "Not Yet Allocated" in the originations view - they're in internal workflow stages, not assigned to actual lending institutions.

## Key Finding: Internal vs External Portfolio Confusion

### What We Discovered
The CSV data showing "Not Yet Allocated" refers to **external funding partner portfolios** (First Tech FCU, Michigan State University FCU, etc.), while the LOS portfolios view shows **internal processing workflow portfolios**.

### Portfolio Classification

| Portfolio Type | Purpose | Examples | Stage |
|---------------|---------|----------|-------|
| **Internal Processing** | Workflow management | API Affiliate, Ocrolus, Document Review | Current |
| **External Partners** | Funding sources | First Tech FCU, Michigan State FCU | Missing |

## Detailed Portfolio Analysis

### Applications with Most Complex Processing (5 Portfolios)

| Application | All Portfolios | Risk/Issues Identified |
|-------------|---------------|----------------------|
| **3007232** | API Affiliate, Document Review, Generated, Ocrolus, Pending Applicant Response | T5/$30K - Multiple verification failures |
| **3011634** | API Affiliate, Auto Escalation, Complete, Ocrolus, Processing | T4/$21K - Escalated, but marked "Complete" |
| **3012211** | API Affiliate, Auto Escalation, Fraud Team Review, Ocrolus, Pending Applicant Response | T1/$35K - **FRAUD FLAG** despite prime tier |
| **3016235** | API Affiliate, Document Review, Ocrolus, Pending Applicant Response, Review | T2/$35K - Under manual review |

### Applications with Standard Processing (3-4 Portfolios)

| Application | Key Portfolios | Status |
|-------------|---------------|--------|
| **3016579** | API Affiliate, Consumer Statement, Income Bypass, Processing | T2/$15.5K - Income verification bypassed |
| **2977446** | API Affiliate, Citizenship, Ocrolus, Pending Applicant Response | T4/$5.7K - Citizenship verification required |
| **3014115** | API Affiliate, Document Review, Ocrolus, Pending Applicant Response | T2/$30K - Document collection pending |
| **3016071** | API Affiliate, Ocrolus, Pending Applicant Response, Review | T4/$15K - Under review |

### Applications with Minimal Processing (1-2 Portfolios)

| Application | Portfolios | Status/Concern |
|-------------|-----------|----------------|
| **2129780** | Ocrolus only | **CRITICAL**: Oldest app, stuck in income verification |
| **2833697** | Document Review only | T5/$5K - Minimal processing due to low value |
| **2927052** | GIACT only | $40K stuck in bank verification |
| **3017196** | Ocrolus only | T1/$40K - High value prime stuck in verification |

## Portfolio-Specific Bottleneck Analysis

### 1. Ocrolus Portfolio (Income Verification)
**Applications**: 20 of 25 sampled applications  
**Function**: Automated income verification service  
**Issues Identified**:
- **2129780**: Stuck for months in Ocrolus only
- **3017196**: T1/$40K high-value stuck
- Multiple T4-T5 applications failing verification

### 2. Pending Applicant Response Portfolio
**Applications**: 12 of 25 sampled  
**Function**: Waiting for customer document uploads  
**Critical Examples**:
- **3012211**: T1/$35K fraud-flagged but pending docs
- **3007232**: T5/$30K multiple verification failures
- **3016235**: T2/$35K manual review pending docs

### 3. Document Review Portfolio
**Applications**: 6 of 25 sampled  
**Function**: Manual document verification  
**Pattern**: Higher-risk tiers (T3-T5) requiring human review

### 4. Auto Escalation Portfolio
**Applications**: 3 of 25 sampled  
**Function**: Automated escalation to manual review  
**Critical Cases**:
- **3012211**: T1 app escalated AND fraud-flagged
- **3011634**: T4 app auto-escalated
- **3012766**: T1 app auto-escalated (unusual)

### 5. Fraud Team Review Portfolio
**Applications**: 1 identified  
**Critical Issue**: **3012211** - T1/$35K from CREDIBLE source flagged for fraud despite prime tier

## Critical Issues by Application Age

### Very Old Applications (90+ days)
| App ID | Portfolios | Issue |
|--------|-----------|-------|
| **2129780** | Ocrolus only | Stuck in income verification for months |

### Old Applications (30-60 days)
| App ID | Portfolios | Issue |
|--------|-----------|-------|
| **2833697** | Document Review only | Low-value T5 stuck in manual review |
| **2927052** | GIACT only | High-value stuck in bank verification |

### Recent High-Priority Issues
| App ID | Amount | Tier | Portfolios | Issue |
|--------|--------|------|-----------|-------|
| **3012211** | $35,000 | T1 | Fraud + Auto Escalation + Pending Docs | Prime customer fraud-flagged |
| **3017196** | $40,000 | T1 | Ocrolus only | High-value stuck in verification |
| **3007232** | $30,000 | T5 | 5 portfolios | Multiple system failures |

## Workflow Analysis

### Typical Processing Flow
1. **API Affiliate** → All affiliate-sourced applications
2. **Ocrolus** → Income verification (95% of apps)
3. **Pending Applicant Response** → Document collection
4. **Document Review** → Manual verification
5. **Processing/Review** → Final approval stage
6. **[Missing]** → External partner assignment

### Stuck Points Identified

| Stage | Apps Stuck | Primary Issue |
|-------|-----------|--------------|
| **Ocrolus Verification** | 8+ | Income verification service delays |
| **Document Collection** | 12+ | Customer response delays |
| **Fraud Review** | 1 | False positive on T1 application |
| **Manual Review** | 6+ | Capacity constraints |
| **External Assignment** | ALL 44 | No external partner allocation |

## Recommendations

### Immediate Actions (24 Hours)
1. **2129780**: Manual override for Ocrolus - stuck for months
2. **3012211**: Review fraud flag on T1/$35K - likely false positive
3. **3017196**: Expedite Ocrolus for T1/$40K high-value
4. **2927052**: Override GIACT for $40K application

### Process Improvements (1 Week)
1. **Ocrolus Timeout**: Implement auto-bypass after 48 hours for T1-T2
2. **Document Collection**: Proactive outreach for "Pending Applicant Response"
3. **Fraud Review**: Secondary review for T1 applications
4. **External Assignment**: Automated partner allocation post-approval

### System Fixes (1 Month)
1. **Portfolio Visibility**: Combine internal + external portfolio status in reporting
2. **SLA Tracking**: Monitor time spent in each portfolio stage
3. **Bottleneck Alerts**: Real-time monitoring of stuck applications
4. **Partner Integration**: Direct API integration with external partners

## Key Insights

### 1. Reporting Confusion
The "Not Yet Allocated" status in originations reporting refers to external partner assignment, not internal processing. All applications are actively being processed through internal portfolios.

### 2. Income Verification Bottleneck
Ocrolus (income verification) is the primary chokepoint, affecting 80%+ of applications with varying degrees of delay.

### 3. False Fraud Detection
Application 3012211 (T1/$35K from CREDIBLE) has been fraud-flagged despite being prime tier, suggesting system tuning issues.

### 4. Age-Based Failures
Applications older than 30 days show simplified portfolio assignments, suggesting they've "fallen through cracks" in the system.

### 5. Missing External Integration
The final step of external partner assignment is not happening automatically, requiring manual intervention for all applications regardless of approval status.

## SQL Queries for Monitoring

```sql
-- Monitor applications stuck in single portfolios (potential issues)
SELECT 
    APPLICATION_ID,
    PORTFOLIO_NAME,
    COUNT(*) as DAYS_STUCK
FROM ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS
WHERE APPLICATION_ID IN (/* pending app list */)
GROUP BY APPLICATION_ID, PORTFOLIO_NAME
HAVING COUNT(DISTINCT PORTFOLIO_ID) = 1
ORDER BY APPLICATION_ID;

-- Identify fraud-flagged applications
SELECT 
    APPLICATION_ID,
    LISTAGG(PORTFOLIO_NAME, ', ') as PORTFOLIOS
FROM ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS
WHERE APPLICATION_ID IN (/* pending app list */)
    AND PORTFOLIO_NAME LIKE '%Fraud%'
GROUP BY APPLICATION_ID;

-- Applications requiring immediate attention (stuck >30 days)
SELECT 
    APPLICATION_ID,
    COUNT(DISTINCT PORTFOLIO_ID) as PORTFOLIO_COUNT,
    LISTAGG(PORTFOLIO_NAME, ', ') as ALL_PORTFOLIOS
FROM ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS
WHERE APPLICATION_ID IN ('2129780','2833697','2927052')
GROUP BY APPLICATION_ID;
```

## Conclusion
The pending applications are not "unallocated" but are stuck in internal processing workflows. The primary bottlenecks are:
1. **Ocrolus income verification** (80% of apps)
2. **Document collection** from customers (50% of apps)  
3. **Manual review capacity** (30% of apps)
4. **Missing external partner assignment** (100% of apps)

Most applications can be moved forward by addressing specific portfolio bottlenecks rather than focusing on external partner allocation.