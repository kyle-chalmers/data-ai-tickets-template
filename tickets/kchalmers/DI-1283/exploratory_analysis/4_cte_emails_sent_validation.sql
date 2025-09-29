/********************************************************************************************
DI-1283: CTE #4 - Emails Sent Validation - PRIMARY SUSPECT FOR DATA GAP
Purpose: Validate SFMC email metrics from Fivetran integration
Data Sources:
  - BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS (SUSPECT - stops Sept 24)
  - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
********************************************************************************************/

-- CRITICAL: Check DSH_EMAIL_MONITORING_EVENTS data freshness
SELECT
    DATE(EVENT_DATE) AS email_event_date,
    COUNT(*) AS total_events,
    SUM(SENT) AS total_sent,
    COUNT(DISTINCT SUBSCRIBER_KEY) AS unique_subscribers,
    COUNT(DISTINCT SEND_TABLE_EMAIL_NAME) AS unique_campaigns
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
WHERE DATE(EVENT_DATE) BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY DATE(EVENT_DATE)
ORDER BY email_event_date DESC;

-- Check last 10 days of email event data to confirm gap
SELECT
    DATE(EVENT_DATE) AS email_event_date,
    COUNT(*) AS event_count,
    SUM(SENT) AS emails_sent
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
WHERE DATE(EVENT_DATE) >= DATEADD('day', -10, CURRENT_DATE())
GROUP BY DATE(EVENT_DATE)
ORDER BY email_event_date DESC;

-- Check subscriber key matching dependency
WITH subscriber_key_matching AS (
    SELECT
        vlcc.CUSTOMER_ID,
        vlcc.LOAN_ID AS APPLICATION_ID,
        va.APPLICATION_GUID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT VLCC
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT VA
        ON VA.LOAN_ID::VARCHAR = VLCC.LOAN_ID::VARCHAR
    WHERE VLCC.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    QUALIFY ROW_NUMBER() OVER (PARTITION BY vlcc.CUSTOMER_ID ORDER BY ORIGINATION_DATE DESC, APPLICATION_STARTED_DATE DESC) = 1
)
SELECT
    'Subscriber key matching table' AS check_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT CUSTOMER_ID) AS unique_customers
FROM subscriber_key_matching;

-- Attempt full emails_sent CTE for Sept 20-24 (before data gap)
WITH subscriber_key_matching AS (
    SELECT
        vlcc.CUSTOMER_ID,
        vlcc.LOAN_ID AS APPLICATION_ID,
        va.APPLICATION_GUID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT VLCC
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT VA
        ON VA.LOAN_ID::VARCHAR = VLCC.LOAN_ID::VARCHAR
    WHERE VLCC.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    QUALIFY ROW_NUMBER() OVER (PARTITION BY vlcc.CUSTOMER_ID ORDER BY ORIGINATION_DATE DESC, APPLICATION_STARTED_DATE DESC) = 1
),
emails_sent AS (
    SELECT
        SUM(a.sent) AS emails_sent,
        DATE(a.EVENT_DATE) AS ASOFDATE,
        CASE
            WHEN b.status = 'Current' AND TO_NUMBER(b.dayspastdue) < 3 THEN 'Current'
            WHEN TO_NUMBER(b.dayspastdue) >= 3 AND TO_NUMBER(b.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN TO_NUMBER(b.dayspastdue) >= 15 AND TO_NUMBER(b.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN TO_NUMBER(b.dayspastdue) >= 30 AND TO_NUMBER(b.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN TO_NUMBER(b.dayspastdue) >= 60 AND TO_NUMBER(b.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN TO_NUMBER(b.dayspastdue) >= 90 THEN 'DPD90+'
            WHEN b.status = 'Sold' THEN 'Sold'
            WHEN b.status = 'Paid in Full' THEN 'Paid in Full'
            WHEN b.status = 'Charge off' THEN 'Charge off'
            WHEN b.status = 'Debt Settlement' THEN 'Debt Settlement'
            WHEN b.status = 'Cancelled' THEN 'Cancelled'
            WHEN b.status IS NULL THEN 'Originated'
        END AS LOANSTATUS,
        b.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
    LEFT JOIN subscriber_key_matching c
        ON a.SUBSCRIBER_KEY::VARCHAR = c.CUSTOMER_ID::VARCHAR
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY b
        ON COALESCE(a.DERIVED_PAYOFFUID, c.APPLICATION_GUID) = b.PAYOFFUID
        AND DATE(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
    WHERE DATE(a.EVENT_DATE) BETWEEN '2025-09-20' AND '2025-09-24'
    GROUP BY b.PORTFOLIONAME, LOANSTATUS, DATE(a.EVENT_DATE)
    HAVING SUM(a.SENT) > 0
)
SELECT
    ASOFDATE,
    LOANSTATUS,
    SUM(emails_sent) AS total_emails_sent,
    COUNT(DISTINCT PORTFOLIONAME) AS portfolio_count
FROM emails_sent
GROUP BY ASOFDATE, LOANSTATUS
ORDER BY ASOFDATE DESC, LOANSTATUS;