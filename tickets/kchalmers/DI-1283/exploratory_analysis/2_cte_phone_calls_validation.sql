/********************************************************************************************
DI-1283: CTE #2 - Phone Calls Validation
Purpose: Validate Genesys phone outreach metrics and activity
Data Sources:
  - BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
  - BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY
********************************************************************************************/

-- Check GENESYS_OUTBOUND_LIST_EXPORTS data for Phone channel
SELECT
    DATE(LOADDATE) AS call_list_date,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PAYOFFUID) AS unique_loans,
    COUNT(DISTINCT "inin-outbound-id") AS unique_outbound_ids,
    COUNT(DISTINCT PORTFOLIONAME) AS portfolio_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
WHERE CHANNEL = 'Phone'
    AND DATE(LOADDATE) BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY DATE(LOADDATE)
ORDER BY call_list_date DESC;

-- Check VW_GENESYS_PHONECALL_ACTIVITY for same period
SELECT
    DATE(INTERACTION_START_TIME) AS call_date,
    COUNT(*) AS total_calls,
    COUNT(DISTINCT CONVERSATIONID) AS unique_conversations,
    COUNT(DISTINCT PAYOFFUID) AS unique_loans,
    COUNT(DISTINCT CASE WHEN DISPOSITION_CODE IS NOT NULL THEN CONVERSATIONID END) AS calls_with_disposition
FROM BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY
WHERE DATE(INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    AND ORIGINATINGDIRECTION = 'outbound'
GROUP BY DATE(INTERACTION_START_TIME)
ORDER BY call_date DESC;

-- Full phone_calls CTE logic for Sept 20-29
WITH phone_calls AS (
    SELECT
        CASE
            WHEN TO_NUMBER(c.dayspastdue) < 3 THEN 'Current'
            WHEN TO_NUMBER(c.dayspastdue) >= 3 AND TO_NUMBER(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN TO_NUMBER(c.dayspastdue) >= 15 AND TO_NUMBER(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN TO_NUMBER(c.dayspastdue) >= 30 AND TO_NUMBER(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN TO_NUMBER(c.dayspastdue) >= 60 AND TO_NUMBER(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN TO_NUMBER(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        c.PORTFOLIONAME,
        DATE(LOADDATE) AS asofdate,
        COUNT(DISTINCT c.PAYOFFUID) AS call_list,
        COUNT(DISTINCT COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)) AS call_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IS NOT NULL
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS connections,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN ('Other::Left Message', 'Voicemail Not Set Up or Full')
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS voicemails_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'Other::Left Message'
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS voicemails_left,
        COUNT(DISTINCT CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS RPCs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH'
            )
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS PTPs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS OTPs
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND b.CALL_DIRECTION = 'outbound'
        AND c."CallRecordLastAttempt-PHONE" IS NULL
        AND DATE(b.INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    WHERE c.CHANNEL = 'Phone'
        AND DATE(c.LOADDATE) BETWEEN '2025-09-20' AND '2025-09-29'
    GROUP BY c.PORTFOLIONAME, asofdate, loanstatus
)
SELECT
    asofdate,
    loanstatus,
    SUM(call_list) AS total_call_list,
    SUM(call_attempted) AS total_attempted,
    SUM(connections) AS total_connections,
    SUM(RPCs) AS total_rpcs,
    SUM(PTPs) AS total_ptps,
    SUM(OTPs) AS total_otps
FROM phone_calls
GROUP BY asofdate, loanstatus
ORDER BY asofdate DESC, loanstatus;