# DI-1223: Suppression Scope Clarification Required

## Business Decision Needed

The ticket mentions excluding Bounce accounts from "internal email campaigns" but the specific scope needs clarification from the business team.

## Current Implementation

The suppression logic has been implemented with a **placeholder scope** that can be easily modified once the business requirements are confirmed.

## Clarification Required

**Question**: Which Happy Money internal campaigns should suppress Bounce accounts?

### Option 1: Collections Email Campaigns Only
- Suppress Bounce accounts from `GR Email` campaigns only
- Allow Bounce accounts in marketing/engagement emails
- **Rationale**: Bounce handles collections, Happy Money handles marketing

### Option 2: All Email Campaigns 
- Suppress from all Happy Money email campaigns:
  - GR Email (collections)
  - Marketing emails
  - Customer engagement emails  
  - Prescreen campaigns
- **Rationale**: Complete email channel separation

### Option 3: All Communication Channels
- Suppress from all Happy Money internal campaigns:
  - All email campaigns
  - Internal SMS campaigns
  - Internal call campaigns
- **Rationale**: Complete customer communication separation

## Current Implementation Status

✅ **Implemented**: Placeholder suppression for `GR Email` campaigns  
⚠️ **Needs Update**: Scope adjustment based on business decision  
📋 **Action Required**: Business team confirmation of suppression scope  

## Technical Implementation Notes

The suppression logic is implemented as a cross-set suppression in `2_bounce_suppression_logic_implementation.sql`:

```sql
-- Current placeholder (line 45-55)
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Cross Set'  as SUPPRESSION_TYPE,
       'BOUNCE'     as SUPPRESSION_REASON,
       PAYOFFUID,
       'GR Email'   as SET_NAME,    -- TO BE UPDATED based on business decision
       'N/A'        as LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME = 'BOUNCE';
```

## Next Steps

1. **Business Decision**: Determine suppression scope with collections and marketing teams
2. **Update Code**: Modify suppression logic based on confirmed scope  
3. **Testing**: Validate suppression works correctly for all determined campaign types
4. **Documentation**: Update implementation docs with final scope

## Stakeholders for Decision

- **Collections Team**: Lisa Carney, Maria Mosolova, Kelvin Marin-Solis
- **Marketing Team**: [To be identified]
- **Product/Servicing**: Jenny Kohrumel
- **Risk Team**: Davis Mahony, Harjot Dadial (for validation)

## Timeline Impact

This clarification is needed before October 14th go-live date. The technical implementation can be updated quickly once scope is confirmed.