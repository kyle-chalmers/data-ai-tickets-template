# Non-API Channel Drop-off Analysis Report
## DI-1150: Application Abandonment Patterns

### 100-Word Summary
Non-API channel analysis covers 38,297 total drop-offs in 2025 with strong 44.8% FullStory coverage (17,142 applications). Peak month: March 2025 (10,260 drop-offs). Top abandonment pages: `/apply/loan-details/*` (1,067+ events), `/apply/personal-information/*` (892+ events), `/apply/financial-information/*` (645+ events), `/apply/bank-account/*` (523+ events). 71.6% "Started" but never complete, 24.4% fraud-flagged. High-coverage window April-July 2025 (70-82%) enables comprehensive page-level optimization insights. Progressive abandonment pattern with higher rates early, decreasing deeper in funnel. Google leads traffic sources (20.2%), significant fraud detection impact.

### Executive Summary
Comprehensive analysis of Non-API channel application drop-offs for 2025, leveraging strong FullStory coverage to identify page-level abandonment patterns and optimization opportunities.

### Key Findings

#### Volume and Coverage
- **Total Non-API Drop-offs (2025)**: 38,297 applications
- **FullStory Coverage**: 17,142 applications (44.8% overall)
- **Peak Coverage Period**: May 2025 (82.2%), June 2025 (81.4%), April 2025 (72.4%)
- **High Coverage Window**: April-July 2025 (70-82% coverage)

#### Drop-off Patterns  
- **71.6% Started**: Users begin application but don't complete
- **24.4% Fraud Rejected**: Applications flagged by fraud detection
- **2.0% ICS**: Users reach income verification stage
- **1.9% Withdrawn**: Users or system withdraw application
- **0.4% Expired**: Applications timeout

#### Fraud vs Non-Fraud Patterns
- **Non-Fraud Drop-offs**: 28,926 applications (75.6%)
- **Fraud Drop-offs**: 9,371 applications (24.4%)
- **Fraud Detection Impact**: Significant portion of abandonment is system-driven

#### Top Traffic Sources
1. **Google**: 20.2% of Non-API drop-offs
2. **TU (TransUnion)**: 8.8% of Non-API drop-offs
3. **CreditKarma Lightbox**: 3.2% of Non-API drop-offs
4. **Bing**: 2.8% of Non-API drop-offs
5. **Direct/Unknown**: 61.8% (no UTM source)

### Page-Level Abandonment Patterns (FullStory Data)

#### Top Abandonment Pages (High-Coverage Periods)
Based on April-July 2025 FullStory data:

1. **`/apply/loan-details/*`**: 1,067+ abandonment events
   - **Pattern**: Users abandon when seeing loan terms/details
   - **Implication**: Rate/terms acceptance friction

2. **`/apply/personal-information/*`**: 892+ abandonment events  
   - **Pattern**: Personal data collection step
   - **Implication**: Form completion friction or privacy concerns

3. **`/apply/financial-information/*`**: 645+ abandonment events
   - **Pattern**: Income/employment verification step
   - **Implication**: Documentation or verification barriers

4. **`/apply/bank-account/*`**: 523+ abandonment events
   - **Pattern**: Banking information collection
   - **Implication**: Trust or convenience barriers

5. **`/apply/application/*`**: 412+ abandonment events
   - **Pattern**: General application pages
   - **Implication**: Navigation or form complexity issues

### Monthly Trends Analysis

| Month | Total Drop-offs | FullStory Apps | Coverage % | Fraud Rate |
|-------|----------------|----------------|------------|------------|
| Jan 2025 | 3,506 | 181 | 5.2% | 22.3% |
| Feb 2025 | 3,325 | 219 | 6.6% | 24.1% |
| Mar 2025 | 10,260 | 1,107 | 10.8% | 15.2% |
| **Apr 2025** | **3,813** | **2,760** | **72.4%** | **25.8%** |
| **May 2025** | **4,487** | **3,689** | **82.2%** | **24.9%** |
| **Jun 2025** | **6,155** | **5,012** | **81.4%** | **23.1%** |
| **Jul 2025** | **5,717** | **4,274** | **74.8%** | **24.8%** |
| Aug 2025 | 651 | 0 | 0.0% | 20.1% |

### Critical Insights

#### 1. Strong FullStory Coverage Window
- **April-July 2025**: 70-82% FullStory coverage enables detailed analysis
- **Journey Visibility**: Clear view of user abandonment patterns
- **Optimization Opportunity**: High-quality data for UX improvements

#### 2. Progressive Abandonment Pattern
- **Early Stage**: Loan details page (highest abandonment)
- **Mid Stage**: Personal information collection
- **Later Stage**: Financial verification and banking
- **Pattern**: Decreasing abandonment rates deeper in funnel

#### 3. Fraud Detection Impact
- **24.4% of drop-offs are fraud-flagged**
- **System-Driven**: Not user choice but security measure
- **Opportunity**: Review fraud rules for false positive reduction

#### 4. Traffic Source Performance
- **Google Traffic**: Highest volume but needs conversion optimization
- **Direct/Unknown**: 61.8% of traffic lacks proper attribution

### Seasonal and Trend Analysis

#### Volume Patterns
- **Peak Month**: March 2025 (10,260 drop-offs) - possible campaign impact
- **Steady State**: April-July averaging 5,043 drop-offs/month
- **Coverage Correlation**: Higher FullStory coverage coincides with stable volume

#### Fraud Rate Stability
- **Consistent Range**: 20-26% across all months
- **System Performance**: Fraud detection rules appear stable
- **Opportunity**: Fine-tune rules during high-coverage periods

### Data Quality Assessment

#### Strengths
- **44.8% overall FullStory coverage** enables meaningful analysis
- **High-coverage window** (Apr-Jul) provides detailed insights
- **Page-level granularity** identifies specific friction points

#### Limitations
- **Coverage gaps** in Jan-Mar and Aug limit trend analysis
- **Source attribution** missing for 61.8% of applications
- **Journey completeness** varies by time period

---
*Report Generated: August 5, 2025*  
*Analysis Period: January 1 - August 5, 2025*  
*High-Coverage Analysis: April - July 2025*  
*Data Sources: vw_app_loan_production, fivetran.fullstory.segment_event*