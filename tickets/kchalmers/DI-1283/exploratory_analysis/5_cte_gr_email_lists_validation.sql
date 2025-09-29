/********************************************************************************************
DI-1283: CTE #5 - GR Email Lists Validation
Purpose: Validate Goal Realignment email list exports
Data Sources:
  - BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
  - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
********************************************************************************************/

-- Check RPT_OUTBOUND_LISTS_HIST for GR Email set
SELECT
    LOAD_DATE,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PAYOFFUID) AS unique_loans,
    COUNT(CASE WHEN SUPPRESSION_FLAG = false THEN 1 END) AS non_suppressed_records,
    COUNT(CASE WHEN SUPPRESSION_FLAG = true THEN 1 END) AS suppressed_records
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
WHERE SET_NAME = 'GR Email'
    AND LOAD_DATE BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY LOAD_DATE
ORDER BY LOAD_DATE DESC;

-- Check loan tape matching for GR Email list
SELECT
    OL.LOAD_DATE,
    COUNT(OL.PAYOFFUID) AS gr_email_list_count,
    COUNT(LT.PAYOFFUID) AS matched_to_loan_tape,
    COUNT(OL.PAYOFFUID) - COUNT(LT.PAYOFFUID) AS unmatched_loans
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST AS OL
LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY AS LT
    ON OL.PAYOFFUID = LT.PAYOFFUID
    AND OL.LOAN_TAPE_ASOFDATE = LT.ASOFDATE
WHERE OL.SET_NAME = 'GR Email'
    AND OL.SUPPRESSION_FLAG = false
    AND OL.LOAD_DATE BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY OL.LOAD_DATE
ORDER BY OL.LOAD_DATE DESC;

-- Full gr_email_lists CTE logic for Sept 20-29
WITH gr_email_lists AS (
    SELECT
        COUNT(OL.PAYOFFUID) AS gr_email_list,
        OL.LOAD_DATE AS ASOFDATE,
        CASE
            WHEN TO_NUMBER(LT.dayspastdue) < 3 THEN 'Current'
            WHEN TO_NUMBER(LT.dayspastdue) >= 3 AND TO_NUMBER(LT.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN TO_NUMBER(LT.dayspastdue) >= 15 AND TO_NUMBER(LT.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN TO_NUMBER(LT.dayspastdue) >= 30 AND TO_NUMBER(LT.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN TO_NUMBER(LT.dayspastdue) >= 60 AND TO_NUMBER(LT.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN TO_NUMBER(LT.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        LT.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST AS OL
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY AS LT
        ON OL.PAYOFFUID = LT.PAYOFFUID
        AND OL.LOAN_TAPE_ASOFDATE = LT.ASOFDATE
    WHERE OL.SET_NAME = 'GR Email'
        AND OL.SUPPRESSION_FLAG = false
        AND OL.LOAD_DATE BETWEEN '2025-09-20' AND '2025-09-29'
    GROUP BY LT.PORTFOLIONAME, loanstatus, OL.LOAD_DATE
)
SELECT
    ASOFDATE,
    loanstatus,
    SUM(gr_email_list) AS total_gr_email_list,
    COUNT(DISTINCT PORTFOLIONAME) AS portfolio_count
FROM gr_email_lists
GROUP BY ASOFDATE, loanstatus
ORDER BY ASOFDATE DESC, loanstatus;