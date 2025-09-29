/********************************************************************************************
DI-1283: CTE #3 - Sent Texts Validation
Purpose: Validate Genesys SMS/text outreach metrics and activity
Data Sources:
  - BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
  - BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY
********************************************************************************************/

-- Check GENESYS_OUTBOUND_LIST_EXPORTS data for Text channel
SELECT
    DATE(DATEADD('day', -1, RECORD_INSERT_DATE)) AS text_list_date,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PAYOFFUID) AS unique_loans,
    COUNT(DISTINCT "inin-outbound-id") AS unique_outbound_ids,
    COUNT(DISTINCT PORTFOLIONAME) AS portfolio_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
WHERE CHANNEL = 'Text'
    AND DATE(DATEADD('day', -1, RECORD_INSERT_DATE)) BETWEEN '2025-09-20' AND '2025-09-29'
GROUP BY DATE(DATEADD('day', -1, RECORD_INSERT_DATE))
ORDER BY text_list_date DESC;

-- Check VW_GENESYS_SMS_ACTIVITY for same period
SELECT
    DATE(INTERACTION_START_TIME) AS text_date,
    COUNT(*) AS total_texts,
    COUNT(DISTINCT CONVERSATIONID) AS unique_conversations,
    COUNT(DISTINCT PAYOFFUID) AS unique_loans,
    COUNT(DISTINCT CASE WHEN DISPOSITION_CODE IS NOT NULL THEN CONVERSATIONID END) AS texts_with_disposition
FROM BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY
WHERE DATE(INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    AND ORIGINATINGDIRECTION = 'outbound'
GROUP BY DATE(INTERACTION_START_TIME)
ORDER BY text_date DESC;

-- Full sent_texts CTE logic for Sept 20-29
WITH sent_texts AS (
    SELECT
        c.PORTFOLIONAME,
        CASE
            WHEN TO_NUMBER(c.dayspastdue) < 3 THEN 'Current'
            WHEN TO_NUMBER(c.dayspastdue) >= 3 AND TO_NUMBER(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN TO_NUMBER(c.dayspastdue) >= 15 AND TO_NUMBER(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN TO_NUMBER(c.dayspastdue) >= 30 AND TO_NUMBER(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN TO_NUMBER(c.dayspastdue) >= 60 AND TO_NUMBER(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN TO_NUMBER(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE)) AS asofdate,
        COUNT(*) AS text_list,
        COUNT(COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)) AS texts_sent,
        COUNT(CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS text_RPCs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH'
            )
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS text_PTPs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
            THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
        END) AS text_OTPs
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE))
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND c."SmsLastAttempt-PHONE" IS NULL
        AND DATE(b.INTERACTION_START_TIME) BETWEEN '2025-09-20' AND '2025-09-29'
    WHERE c.CHANNEL = 'Text'
        AND DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE)) BETWEEN '2025-09-20' AND '2025-09-29'
    GROUP BY c.PORTFOLIONAME, loanstatus, asofdate
)
SELECT
    asofdate,
    loanstatus,
    SUM(text_list) AS total_text_list,
    SUM(texts_sent) AS total_texts_sent,
    SUM(text_RPCs) AS total_text_rpcs,
    SUM(text_PTPs) AS total_text_ptps,
    SUM(text_OTPs) AS total_text_otps
FROM sent_texts
GROUP BY asofdate, loanstatus
ORDER BY asofdate DESC, loanstatus;