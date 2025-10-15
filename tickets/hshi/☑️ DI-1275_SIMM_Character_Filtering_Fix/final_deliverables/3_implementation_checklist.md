# SIMM Character Filtering Bug - Implementation Checklist

## Pre-Implementation Checklist

### 🔍 Analysis and Validation
- [ ] **Run pre-fix validation queries** (`2_validation_queries.sql` queries 1-3)
- [ ] **Document current campaign volumes** for Call List and SMS
- [ ] **Identify specific test accounts** (SIMM charge-off and payment reminder accounts)
- [ ] **Review business impact estimates** with Collections team

### 📋 Stakeholder Communication
- [ ] **Notify Collections Management Team** of planned fix (Lisa Carney, Kelvin Marin-Solis)
- [ ] **Coordinate with Kyle** (who confirmed the issue understanding)
- [ ] **Schedule implementation window** during low-impact period
- [ ] **Set up monitoring alerts** for campaign volume changes

### 🛠️ Technical Preparation
- [ ] **Create backup** of current BI-2482 file
- [ ] **Test queries in development environment** using validation queries 4-5
- [ ] **Verify development environment access** and database connections
- [ ] **Prepare rollback plan** (revert to previous character filtering logic)

## Implementation Steps

### 📝 Code Changes
- [ ] **Update Call List logic** (line 237 in BI-2482_Outbound_List_Generation_for_GR.py)
  ```sql
  -- Replace character filtering with DPD-conditional logic
  and (
    (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
    OR
    (DAYSPASTDUE not between 3 and 119)
  )
  ```

- [ ] **Update SMS logic** (line 295 in BI-2482_Outbound_List_Generation_for_GR.py)
  ```sql
  -- Replace character filtering with DPD-conditional logic
  and (
    (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
    OR
    (DAYSPASTDUE not between 3 and 119)
  )
  ```

- [ ] **Verify Remitter logic remains unchanged** (line 260 - working correctly)

### 🧪 Development Testing
- [ ] **Deploy to development environment**
- [ ] **Run full BI-2482 job** in dev to verify no errors
- [ ] **Execute post-fix validation queries** (queries 4-5 in validation file)
- [ ] **Compare results** with expected outcomes
- [ ] **Verify DPD 3-119 allocation** still shows ~50/50 Happy Money/SIMM split

## Post-Implementation Checklist

### ✅ Immediate Validation (Day 1)
- [ ] **Monitor job execution** for any failures or errors
- [ ] **Run post-implementation queries** (queries 6-8 in validation file)
- [ ] **Verify campaign volume increases** in Call List and SMS
- [ ] **Check specific test accounts** appear in appropriate campaigns
- [ ] **Validate SIMM DPD 3-119 allocation** still working correctly

### 📊 Business Impact Assessment (Day 2-7)
- [ ] **Compare campaign volumes** before/after implementation
- [ ] **Monitor collections performance** on newly included accounts
- [ ] **Track customer communication metrics** for payment reminders
- [ ] **Calculate actual recovery impact** using query 9
- [ ] **Document lessons learned** and any unexpected outcomes

### 🔄 Ongoing Monitoring (Week 1-2)
- [ ] **Daily volume monitoring** for any unusual patterns
- [ ] **Collections team feedback** on account quality and performance
- [ ] **System performance monitoring** (ensure no degradation in job runtime)
- [ ] **Error rate monitoring** for any new failures or issues

## Rollback Plan (If Needed)

### 🚨 Rollback Triggers
- Job failures or errors in BI-2482
- Significant unexpected volume changes (>20% variance)
- Collections team reports data quality issues
- System performance degradation

### 🔄 Rollback Steps
1. **Immediate action**: Revert to backed-up version of BI-2482 file
2. **Communication**: Notify stakeholders of rollback and reason
3. **Investigation**: Analyze root cause of issues
4. **Re-planning**: Develop revised approach based on findings

## Success Metrics

### 📈 Expected Improvements
- **Call List "Charge off" volume increase**: 10-25% (estimate based on SIMM allocation)
- **SMS Payment Reminder coverage**: 100% of eligible customers (including SIMM)
- **Collections recovery improvement**: Measurable increase in charge-off recoveries
- **Customer communication completeness**: No gaps in payment notifications

### 🎯 Key Performance Indicators
- Zero job failures or errors
- Expected volume increases without data quality issues
- Positive Collections team feedback on account quality
- Maintained DPD 3-119 allocation accuracy (~50/50 split)

## Team Contacts

### 👥 Key Stakeholders
- **Collections Management**: Lisa Carney, Kelvin Marin-Solis
- **Technical Validation**: Kyle (confirmed issue understanding)
- **Implementation Lead**: Hongxia Shi
- **Business Owner**: Collections Management Team

### 📞 Escalation Path
1. **Technical Issues**: Hongxia Shi → Data Engineering Team
2. **Business Impact**: Collections Management → Business Leadership
3. **System Performance**: Platform Engineering Team
4. **Rollback Decision**: Joint decision with Collections and Engineering leadership

---

**Implementation Timeline**: 1-2 days
**Risk Level**: Low (additive logic, easy rollback)
**Business Priority**: Medium (affects collections efficiency)

*Checklist completed by: [Name]*
*Implementation date: [Date]*
*Sign-off: [Stakeholder approvals]*