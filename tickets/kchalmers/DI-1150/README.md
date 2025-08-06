# DI-1150: Comprehensive Application Drop-off Analysis
## API vs Non-API Channels with FullStory Journey Integration

---

## 📋 **Project Overview**

Comprehensive analysis of application abandonment patterns across API and Non-API channels for 2025, integrated with FullStory user journey data to identify page-level friction points, temporal trends, and optimization opportunities.

**Analysis Period:** January 1 - August 5, 2025  
**Scope:** Complete 2025 drop-off analysis with multi-timeframe trending  
**Integration:** FullStory page-level journey tracking and abandonment pattern analysis

---

## 🎯 **Executive Summary**

### **2025 Drop-off Volume & FullStory Coverage**
- **API Channel**: 3,652 total drop-offs, **8.1% FullStory coverage** (296 applications)
- **Non-API Channel**: 38,297 total drop-offs, **44.8% FullStory coverage** (17,142 applications)
- **High-Coverage Period**: April-July 2025 (70-82% Non-API FullStory coverage)
- **Data Quality**: April-July window enables detailed page-level optimization analysis

### **Critical Insights by Channel**

#### **🔗 API Channel (Limited FullStory Visibility)**
- **84.4%** abandon at "Affiliate Landed" status → **major partner referral friction**
- **Top Partners Driving Drop-offs**: Even Financial (33.6%), LendingTree (15.4%)
- **FullStory Coverage Gap**: Only 8.1% coverage limits detailed journey analysis
- **Primary Abandonment Pages**: `/apply/api-aff-app-summary/*`, `/apply/route/application/*`
- **Journey Pattern**: Early abandonment immediately after partner referral

#### **🎯 Non-API Channel (Strong FullStory Coverage)**
- **71.6%** "Started" applications never complete (**28,926 applications**)
- **24.4%** flagged as "Fraud Rejected" (**9,371 applications**)
- **Page-Level Friction Points Identified**:
  - **`/apply/loan-details/*`**: 1,067+ abandonment events (loan terms friction)
  - **`/apply/personal-information/*`**: 892+ events (form completion barriers)
  - **`/apply/financial-information/*`**: 645+ events (verification hurdles)
  - **`/apply/bank-account/*`**: 523+ events (trust/convenience barriers)
- **Journey Pattern**: Progressive abandonment with decreasing rates deeper in funnel

### **📈 Temporal Trends & Patterns**

#### **Monthly Analysis**
- **Peak Volume**: March 2025 (10,260 Non-API drop-offs)
- **Stable Period**: April-July 2025 (strong FullStory coverage window)
- **Fraud Rate**: Consistent 20-26% across all months (system stability)
- **Coverage Quality**: April-July enables actionable page-level insights

#### **Journey Intelligence**
- **Progressive Abandonment**: Higher abandonment rates early in funnel, decreasing deeper
- **Channel Differences**: API abandons at entry point, Non-API abandons mid-flow
- **Fraud Impact**: 24.4% of Non-API abandonment is system-driven, not user choice
- **Seasonal Patterns**: Identifiable volume fluctuations with coverage correlations

---

## 📊 **Key Findings & Actionable Insights**

### **🚨 Immediate Optimization Opportunities**

1. **Non-API Loan Details Page** (Highest Priority)
   - **1,067+ abandonment events** during April-July 2025
   - **Root Cause**: Loan terms/rate acceptance friction
   - **Action**: A/B test rate presentation and terms clarity

2. **API Partner Referral Flow** (High Impact)
   - **84.4% abandon at "Affiliate Landed"** across all partners
   - **Top Partners**: Even Financial + LendingTree = 49% of all API drop-offs
   - **Action**: Partner-specific landing page optimization + pre-qualification review

3. **Non-API Personal Information Form** (Medium Priority)
   - **892+ abandonment events** during high-coverage window
   - **Root Cause**: Form completion barriers or privacy concerns
   - **Action**: Implement progressive disclosure + completion progress indicators

4. **Fraud Detection Rule Review** (Strategic)
   - **9,371 applications flagged** as fraud during 2025
   - **Consistency**: 20-26% fraud rate across all months
   - **Action**: Analyze for false positives during high-coverage periods

### **🔍 Technical Insights**

#### **FullStory Coverage Analysis**
- **API Channel Tracking Gap**: Investigation needed for 91.9% missing coverage
- **Non-API High-Quality Window**: April-July 2025 provides actionable data
- **Coverage Correlation**: Better tracking coincides with stable application volume
- **Recommendation**: Extend high-coverage tracking methodology to full year

#### **Page Path Normalization Success**
- **Raw Paths**: `/apply/loan-details/12345` → **Normalized**: `/apply/loan-details/*`
- **Pattern Detection**: Enables aggregated analysis across all applications
- **Journey Mapping**: Identifies common abandonment sequences
- **Scalability**: Framework supports ongoing pattern monitoring

---

## 📁 **Repository Structure**

```
DI-1150/
├── README.md                                    # This comprehensive documentation
├── 📂 sql_queries/                             # Complete SQL analysis suite
│   ├── 1_drop_off_summary_stats.sql           # Overall drop-off rates by channel
│   ├── 2_api_dropoffs_extract.sql             # API channel data extraction
│   ├── 3_non_api_dropoffs_extract.sql         # Non-API channel data extraction  
│   ├── 4_non_api_fraud_analysis.sql           # Fraud pattern analysis
│   ├── 5_fullstory_journey_analysis.sql       # FullStory integration queries
│   └── query_explanation.md                   # Step-by-step SQL logic breakdown
├── 📂 final_deliverables/                     # Complete analysis outputs
│   ├── 📂 data_extracts/                      # All analysis datasets (12 files)
│   │   ├── comprehensive_dropoff_analysis.csv # Complete 2025 master dataset
│   │   ├── fullstory_coverage_analysis.csv   # Coverage metrics by channel/month
│   │   ├── api_channel_page_analysis.csv     # API page-level patterns
│   │   ├── non_api_channel_page_analysis.csv # Non-API page-level patterns
│   │   ├── monthly_trending_analysis.csv     # Monthly trends with coverage
│   │   ├── weekly_trending_analysis.csv      # Weekly pattern analysis
│   │   ├── daily_trending_analysis.csv       # Daily granular trending
│   │   └── [5 additional analysis files]     # Original + expanded datasets
│   ├── 📋 API_Channel_Summary_Report.md       # Complete API analysis report
│   ├── 📋 Non_API_Channel_Summary_Report.md   # Complete Non-API analysis report
│   ├── 🐍 comprehensive_visualization_analysis.py # Advanced analytics script
│   └── 🐍 dropoff_analysis.py                # Original analysis script
├── 📂 reports/                              # Channel-specific analysis reports
│   ├── API_Channel_Analysis.md              # API insights & recommendations  
│   └── Non_API_Channel_Analysis.md          # Non-API optimization guide
└── 📂 documentation/                        # Technical documentation
    ├── SQL_Query_Guide.md                   # Step-by-step SQL explanations
    └── Technical_Methodology.md             # Analysis methodology & approach
```

### **🚀 Quick Start**
```bash
python analysis_script.py    # Run complete analysis
```

---

## 🔧 **SQL Query Methodology**

### **Multi-Step Analysis Approach**

#### **1. Drop-off Identification Logic**
```sql
WHERE applied_ts IS NULL  -- Core filter: never completed application
AND ((funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL) 
     OR funnel_type = 'Non-API')
```

#### **2. Page Path Normalization**
```sql
CASE 
  WHEN page_path_str LIKE '/apply/loan-details/%' THEN '/apply/loan-details/*'
  WHEN page_path_str LIKE '/apply/%' THEN REGEXP_REPLACE(page_path_str, '/[0-9]+', '/*')
  ELSE page_path_str
END as normalized_page_path
```

#### **3. Last Page Detection**
```sql
ROW_NUMBER() OVER (PARTITION BY evt_application_id_str ORDER BY event_start DESC) as rn
-- WHERE rn = 1 gives the final page before abandonment
```

#### **4. Coverage Assessment Strategy**
```sql
LEFT JOIN -- Preserves all drop-offs for complete coverage analysis
CASE WHEN fullstory_data IS NOT NULL THEN 1 ELSE 0 END as has_journey_data
```

### **Query Execution Order**
1. **Summary Statistics** → Overall drop-off rates by channel
2. **Data Extraction** → Channel-specific application details  
3. **Fraud Analysis** → Pattern identification and impact assessment
4. **FullStory Integration** → Journey mapping and page-level insights
5. **Temporal Analysis** → Monthly/weekly/daily trending patterns

---

## 📈 **Analysis Results & Data Assets**

### **📊 Comprehensive Datasets Available**

| Dataset | Purpose | Records | Key Insights |
|---------|---------|---------|--------------|
| **comprehensive_dropoff_analysis.csv** | Master 2025 dataset | 10,000+ | Complete application + journey data |
| **fullstory_coverage_analysis.csv** | Coverage assessment | By month/channel | Quality periods identification |
| **api_channel_page_analysis.csv** | API page patterns | Aggregated | Partner-specific abandonment |
| **non_api_channel_page_analysis.csv** | Non-API page patterns | Aggregated | Page-level friction points |
| **monthly_trending_analysis.csv** | Monthly trends | 16 months | Volume + coverage correlation |
| **weekly_trending_analysis.csv** | Weekly patterns | 32+ weeks | Short-term trend identification |
| **daily_trending_analysis.csv** | Daily granular | 66+ days | Granular pattern analysis |

### **📋 Executive Reports**

#### **API Channel Summary Report**
- **Volume Analysis**: 3,652 drop-offs across 2025
- **Partner Performance**: Even Financial & LendingTree optimization opportunities  
- **Coverage Gaps**: FullStory tracking investigation priorities
- **Recommendations**: 4 immediate actions + 3 strategic initiatives

#### **Non-API Channel Summary Report**  
- **Page-Level Insights**: Top 5 abandonment pages with event counts
- **Fraud Analysis**: 9,371 applications flagged for review
- **High-Coverage Window**: April-July optimization roadmap
- **Journey Patterns**: Progressive abandonment funnel analysis

---

## 🎯 **Immediate Action Items**

### **🚀 Quick Wins (Next 30 Days)**

1. **Non-API Loan Details Page Optimization**
   - **Impact**: 1,067+ abandonment events during high-coverage period
   - **Actions**: A/B test rate presentation, terms clarity, acceptance flow
   - **Measurement**: Track abandonment rate reduction during next coverage period

2. **API Partner Landing Page Audit**
   - **Impact**: 84.4% abandon at "Affiliate Landed" across all partners
   - **Actions**: Audit Even Financial & LendingTree landing experiences
   - **Measurement**: Partner-specific conversion rate improvements

3. **FullStory Tracking Investigation**
   - **Impact**: API channel 91.9% coverage gap limits optimization ability
   - **Actions**: Technical audit of API flow tracking implementation
   - **Measurement**: Achieve >50% API channel FullStory coverage

### **📊 Strategic Initiatives (90 Days)**

1. **Comprehensive Funnel Optimization Program**
   - Use April-July high-coverage data for detailed UX analysis
   - Implement page-by-page conversion rate improvement initiatives
   - Create real-time abandonment prevention intervention system

2. **Fraud Detection Rule Optimization**
   - Analyze 9,371 flagged applications for false positive patterns
   - Implement refined rules during high-coverage periods for measurement
   - Balance fraud prevention with conversion optimization

3. **Ongoing Monitoring Framework**
   - Extend high-coverage tracking methodology to full year
   - Create monthly abandonment pattern dashboards
   - Establish automated alerting for significant pattern changes

---

## 💡 **Technical Methodology & Approach**

### **Data Integration Strategy**
- **Primary Source**: `business_intelligence.analytics.vw_app_loan_production`
- **Journey Data**: `fivetran.fullstory.segment_event`  
- **Integration Method**: LEFT JOIN with coverage assessment flags
- **Quality Control**: Multi-timeframe analysis with coverage correlation

### **Page Path Normalization Logic**
- **Challenge**: Raw paths include unique application IDs
- **Solution**: Regex-based normalization to group similar pages
- **Benefit**: Enables pattern analysis across thousands of applications
- **Scalability**: Framework supports ongoing pattern detection

### **Temporal Analysis Framework**
- **Monthly**: Strategic trend identification and volume patterns
- **Weekly**: Short-term fluctuation analysis and coverage correlation  
- **Daily**: Granular pattern detection during high-coverage windows
- **Integration**: Multi-timeframe view enables comprehensive optimization strategy

### **Coverage Quality Assessment**
- **Methodology**: Channel-specific coverage rates by time period
- **Quality Threshold**: >70% coverage enables actionable insights
- **High-Quality Window**: April-July 2025 for Non-API channel
- **Application**: Focus optimization efforts on high-coverage periods

---

## 📞 **Next Steps & Stakeholder Engagement**

### **Immediate Stakeholder Reviews**
1. **Product Team**: Page-level optimization priorities based on abandonment data
2. **Partnership Team**: API partner collaboration on conversion improvement
3. **Fraud Team**: 9,371 flagged applications analysis for rule refinement  
4. **Engineering Team**: FullStory tracking enhancement for API channel

### **Implementation Roadmap**
1. **Week 1-2**: Stakeholder workshops on findings and priority setting
2. **Week 3-4**: UX optimization implementation for top abandonment pages
3. **Month 2**: Enhanced tracking deployment and measurement framework
4. **Month 3**: Follow-up analysis with improved data coverage

### **Success Metrics**
- **Non-API Loan Details Page**: Reduce abandonment events by 20%
- **API Partner Referrals**: Improve "Affiliate Landed" → "Started" conversion by 15%
- **FullStory Coverage**: Achieve >50% API channel coverage for future analysis
- **Overall Impact**: Measurable improvement in application completion rates

---

## 🏆 **Project Deliverables Summary**

✅ **Complete 2025 drop-off analysis** with 41,949 total applications analyzed  
✅ **Page-level abandonment patterns** identified through FullStory integration  
✅ **Multi-timeframe trending analysis** (monthly/weekly/daily) for pattern recognition  
✅ **Channel-specific optimization roadmaps** with prioritized action items  
✅ **Comprehensive SQL documentation** with step-by-step methodology explanation  
✅ **Executive summary reports** ready for stakeholder presentation  
✅ **Technical framework** for ongoing monitoring and optimization  

**Ready for immediate implementation and ongoing optimization efforts.**

---
*Analysis Completed: August 5, 2025*  
*Ticket: DI-1150*  
*Analyst: K. Chalmers*  
*Repository: `/tickets/kchalmers/DI-1150/`*