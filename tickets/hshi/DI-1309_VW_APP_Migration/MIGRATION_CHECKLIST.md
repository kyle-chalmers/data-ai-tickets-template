# Migration Checklist

## Pre-Migration

- [ ] Review all 6 assigned jobs in PDF inventory
- [ ] Read meeting notes and understand architecture changes
- [ ] Review new view schemas (VW_APP_LOAN_PRODUCTION, VW_APP_PII, VW_APP_STATUS_TRANSITION)
- [ ] Identify simplest job to start with

## Per Job Migration

### Job: _______________

#### Analysis Phase
- [ ] Read current job code
- [ ] List all legacy views used
- [ ] Identify all fields referenced from legacy views
- [ ] Check if fields exist in new views
- [ ] Document missing fields for Steve
- [ ] Note any CLS data requirements
- [ ] Check for external dependencies

#### Development Phase
- [ ] Create development branch: `DI-1309/<job-name>`
- [ ] Replace VW_APPLICATION with VW_APP_LOAN_PRODUCTION
- [ ] Replace VW_APPLICATION_PII with VW_APP_PII
- [ ] Replace VW_LEAD_PII with VW_APP_PII (add IS_APP_YN filter if needed)
- [ ] Replace VW_APPLICATION_STATUS_TRANSITION with VW_APP_STATUS_TRANSITION
- [ ] Remove DATA_STORE schema references (migrate to ANALYTICS)
- [ ] Update any JOIN conditions
- [ ] Update any WHERE clauses
- [ ] Verify all field references

#### Testing Phase
- [ ] Test in dev environment
- [ ] Compare row counts (before vs after)
- [ ] Validate key metrics match
- [ ] Check for unexpected NULLs
- [ ] Verify external file outputs (if applicable)
- [ ] Run full job end-to-end

#### Review Phase
- [ ] Code review with team
- [ ] Discuss any missing fields with Steve
- [ ] Document any behavioral changes
- [ ] Update job README if needed

#### Deployment Phase
- [ ] Create pull request
- [ ] Get approval from Steve/Tin
- [ ] Merge to main
- [ ] Deploy to production
- [ ] Monitor first production run
- [ ] Mark job as complete

## Recommended Order

### Easy → Hard
1. **BI-1451_Loss_Forecasting** (1 occurrence) ⭐ Start here
2. **DI-497_CRB_Fortress_Reporting** (single view)
3. **BI-2421_Prescreen_Marketing_Data** (2 views)
4. **DI-977_Prescreen_Email_List** (2 views)
5. **DI-986_Outbound_List_Generation** (complete partial migration)
6. **DI-760_Weekly_Data_Feeds** (multiple occurrences, mixed schemas)

## Field Mapping Template

### VW_APPLICATION → VW_APP_LOAN_PRODUCTION
| Legacy Field | New Field | Notes |
|--------------|-----------|-------|
| application_id | application_id | Direct match |
| lead_guid | lead_guid | Direct match |
| ... | ... | ... |
| [missing_field] | ❌ NOT FOUND | Document for Steve |

### VW_APPLICATION_PII → VW_APP_PII
| Legacy Field | New Field | Notes |
|--------------|-----------|-------|
| application_id | application_id | Direct match |
| email | email | Direct match |
| ... | ... | ... |

### VW_LEAD_PII → VW_APP_PII
| Legacy Field | New Field | Notes |
|--------------|-----------|-------|
| lead_guid | lead_guid | Direct match |
| [Add IS_APP_YN filter if needed] | IS_APP_YN | To distinguish apps vs leads |
| ... | ... | ... |

## Issues to Escalate

### Missing Fields
Document here any fields that don't exist in new views:
- Job: _______________
- Legacy View: _______________
- Missing Field: _______________
- Purpose: _______________

### CLS Data Requirements
Document here any CLS-specific data needs:
- Job: _______________
- CLS Fields Needed: _______________
- Use Case: _______________

### External Dependencies
Note any jobs with external file outputs or API calls:
- Job: _______________
- External System: _______________
- Impact: _______________

## Post-Migration

- [ ] Update job documentation
- [ ] Update README in job folder
- [ ] Share completion status in team meeting
- [ ] Close DI-1309 ticket
- [ ] Archive migration notes

---

*Use this checklist for each job migration to ensure completeness*
