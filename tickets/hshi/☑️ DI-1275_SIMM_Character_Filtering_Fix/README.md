# SIMM Character Filtering Bug Fix

## Issue Summary

The current character filtering logic in BI-2482 (outbound list generation) is incorrectly excluding SIMM partner accounts from campaigns that should include all customers regardless of partner allocation. This affects collections efficiency and customer communication for accounts that should return to Happy Money management when outside the DPD 3-119 range.

## Business Impact

### Collections Impact
- **Missed Charge-Off Recovery**: SIMM accounts that charge off should return to Happy Money for internal collections efforts, but are being excluded from Call List "Charge off" campaigns
- **Reduced Collections Effectiveness**: Happy Money cannot work charge-off accounts that were previously allocated to SIMM, leading to potential recovery losses

### Customer Communication Impact
- **Missing Payment Reminders**: SIMM accounts are not receiving SMS payment reminders and due date notifications that should apply to all customers
- **Inconsistent Customer Experience**: Some customers miss important communications based solely on their original partner allocation rather than current account status

### Operational Impact
- **Campaign Underperformance**: Call List and SMS campaigns are operating with reduced account volumes
- **Partner Handoff Gaps**: No clear process for SIMM accounts to transition back to Happy Money management when appropriate

## Root Cause

The character filtering logic (`substring(PAYOFFUID, 16, 1) in ('0','1','2','3','4','5','6','7')`) was designed to allocate DPD 3-119 accounts between Happy Money (0-7) and SIMM (8-f). However, this filtering is incorrectly being applied to ALL campaign types, including:

1. **Charge-off accounts**: Should return to Happy Money regardless of original allocation
2. **Payment reminders**: Should reach all customers regardless of partner status
3. **Due date notifications**: Universal customer communication need

## Solution

Modify the character filtering logic to only apply during the DPD 3-119 range:

**Business Rule**:
- **DPD 3-119**: Apply character allocation (Happy Money 0-7, SIMM 8-f)
- **Outside DPD 3-119**: Include ALL customers (no character filtering)

This ensures partner allocation works correctly while allowing non-DPD3-119 campaigns to reach all appropriate customers.

## Affected Campaigns

- **Call List**: "Charge off" bucket missing SIMM accounts
- **SMS**: Payment reminder and due date campaigns missing SIMM accounts
- **Remitter**: Currently working correctly (no changes needed)

## Priority

**Medium Priority**: Affects ongoing collections and customer communications but does not prevent critical business operations.

---

## Manual Jira Ticket Creation

**Suggested Ticket Details:**
- **Summary**: SIMM Filter Bug
- **Description**: BI-2482 character filtering excludes SIMM accounts from charge-off and payment reminder campaigns. Fix needed to only apply filtering for DPD 3-119 range.
- **Issue Type**: Data Engineering Bug
- **Priority**: Medium
- **Assignee**: hshi@happymoney.com

---

*Created: September 25, 2025*
*Stakeholder Communication Focus: Collections Management Team*