/********************************************************************************************
DI-1283: CTE #1 - DQS (Delinquent Population) Validation
Purpose: Validate the baseline delinquent population metrics from loan tape
Data Source: BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
********************************************************************************************/

-- Check data availability for the investigation period (Sept 20-29, 2025)
SELECT
    DATE(asofdate) AS ASOFDATE,
    COUNT(DISTINCT loanid) AS total_loans,
    COUNT(DISTINCT CASE
        WHEN status NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
        THEN loanid
    END) AS active_loans,
    COUNT(DISTINCT portfolioname) AS portfolio_count
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE DATE(asofdate) BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY DATE(asofdate)
ORDER BY ASOFDATE DESC;

-- Full DQS CTE logic for Sept 20-29
WITH dqs AS (
    SELECT
        DATE(asofdate) AS ASOFDATE,
        CASE
            WHEN status = 'Current' AND TO_NUMBER(dayspastdue) < 3 THEN 'Current'
            WHEN TO_NUMBER(dayspastdue) >= 3 AND TO_NUMBER(dayspastdue) < 15 THEN 'DPD3-14'
            WHEN TO_NUMBER(dayspastdue) >= 15 AND TO_NUMBER(dayspastdue) < 30 THEN 'DPD15-29'
            WHEN TO_NUMBER(dayspastdue) >= 30 AND TO_NUMBER(dayspastdue) < 60 THEN 'DPD30-59'
            WHEN TO_NUMBER(dayspastdue) >= 60 AND TO_NUMBER(dayspastdue) < 90 THEN 'DPD60-89'
            WHEN TO_NUMBER(dayspastdue) >= 90 THEN 'DPD90+'
            WHEN status = 'Sold' THEN 'Sold'
            WHEN status = 'Paid in Full' THEN 'Paid in Full'
            WHEN status = 'Charge off' THEN 'Charge off'
            WHEN status = 'Debt Settlement' THEN 'Debt Settlement'
            WHEN status = 'Cancelled' THEN 'Cancelled'
            WHEN status IS NULL THEN 'Originated'
        END AS loanstatus,
        portfolioname,
        REPLACE(TO_CHAR(portfolioid), '.00000', '') AS portfolioid,
        COUNT(DISTINCT loanid) AS all_active_loans,
        COUNT(DISTINCT CASE
            WHEN loanstatus IN ('DPD90+', 'DPD60-89', 'DPD30-59', 'DPD15-29', 'DPD3-14')
            THEN loanid
            ELSE NULL
        END) AS dq_count
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY AS dlt
    WHERE status NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
        AND DATE(asofdate) BETWEEN '2025-09-20' AND '2025-09-29'
    GROUP BY 1, 2, 3, 4
)
SELECT
    ASOFDATE,
    loanstatus,
    COUNT(DISTINCT portfolioname) AS portfolio_count,
    SUM(all_active_loans) AS total_active_loans,
    SUM(dq_count) AS total_dq_count
FROM dqs
GROUP BY ASOFDATE, loanstatus
ORDER BY ASOFDATE DESC, loanstatus;