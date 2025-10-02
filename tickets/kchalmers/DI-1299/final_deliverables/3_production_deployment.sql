-- DI-1299: Production Deployment for Optimized View
-- Purpose: Deploy optimized view to production with complete email campaign filtering
-- WARNING: This script modifies production BUSINESS_INTELLIGENCE.REPORTING schema
-- REQUIRED: DBA/Admin permissions for execution

-- ==============================================================================
-- PRE-DEPLOYMENT CHECKLIST
-- ==============================================================================
-- [ ] All QC tests passed in development (qc_validation.sql)
-- [ ] Email campaign filtering logic verified
-- [ ] Performance testing completed
-- [ ] Backup plan documented (revert to original view)
-- [ ] Review and approval from Kyle Chalmers

-- ==============================================================================
-- DEPLOYMENT SEQUENCE
-- ==============================================================================

-- Step 1: Rename Current View (Backup)
ALTER VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
RENAME TO VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251002;

-- Step 2: Create Optimized View (Production)
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
COPY GRANTS
AS
-- OPTIMIZATION 1: Calculate minimum dates once (eliminates 6+ correlated subqueries)
WITH min_dates AS (
    SELECT
        MIN(DATE(DATEADD('day', -1, record_insert_date))) as min_record_insert_date,
        MIN(DATE(LOADDATE)) as min_loaddate
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
),
-- OPTIMIZATION 2: Single scan of 533M row MVW_LOAN_TAPE_DAILY_HISTORY table
loan_tape_base AS (
    SELECT
        ASOFDATE,
        PAYOFFUID,
        LOANID,
        STATUS,
        DAYSPASTDUE,
        PORTFOLIONAME,
        PORTFOLIOID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    CROSS JOIN min_dates md
    WHERE DATE(ASOFDATE) >= md.min_record_insert_date
),
-- DQS CTE: Delinquent population metrics
dqs AS (
    SELECT
        DATE(asofdate) AS ASOFDATE,
        CASE
            WHEN dlt.status = 'Current' AND to_number(dlt.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(dlt.dayspastdue) >= 3 AND to_number(dlt.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(dlt.dayspastdue) >= 15 AND to_number(dlt.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(dlt.dayspastdue) >= 30 AND to_number(dlt.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(dlt.dayspastdue) >= 60 AND to_number(dlt.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(dlt.dayspastdue) >= 90 THEN 'DPD90+'
            WHEN dlt.status = 'Sold' THEN 'Sold'
            WHEN dlt.status = 'Paid in Full' THEN 'Paid in Full'
            WHEN dlt.status = 'Charge off' THEN 'Charge off'
            WHEN dlt.status = 'Debt Settlement' THEN 'Debt Settlement'
            WHEN dlt.status = 'Cancelled' THEN 'Cancelled'
            WHEN dlt.status IS NULL THEN 'Originated'
        END AS loanstatus,
        portfolioname,
        REPLACE(TO_CHAR(portfolioid), '.00000', '') as portfolioid,
        COUNT(DISTINCT loanid) AS all_active_loans,
        COUNT(DISTINCT CASE
            WHEN loanstatus IN ('DPD90+', 'DPD60-89', 'DPD30-59', 'DPD15-29', 'DPD3-14')
                THEN loanid
            ELSE NULL
        END) AS dq_count
    FROM loan_tape_base dlt
    WHERE status NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
    GROUP BY 1, 2, 3, 4
),
-- PHONE_CALLS CTE: Phone outreach metrics with double-join pattern
phone_calls AS (
    SELECT
        CASE
            WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        c.PORTFOLIONAME,
        DATE(LOADDATE) as asofdate,
        count(DISTINCT c.PAYOFFUID) as call_list,
        count(distinct COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)) as call_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IS NOT NULL
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS connections,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN ('Other::Left Message', 'Voicemail Not Set Up or Full')
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS voicemails_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'Other::Left Message'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS voicemails_left,
        COUNT(DISTINCT CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS RPCs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH')
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS PTPs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS OTPs,
        PTPs + OTPs AS conversions
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    CROSS JOIN min_dates md
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) >= md.min_loaddate
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND b.CALL_DIRECTION = 'outbound'
        AND c."CallRecordLastAttempt-PHONE" is null
        AND DATE(b.INTERACTION_START_TIME) >= md.min_loaddate
    WHERE c.CHANNEL = 'Phone'
    GROUP BY c.PORTFOLIONAME, asofdate, loanstatus
),
-- SENT_TEXTS CTE: SMS outreach metrics with double-join pattern
sent_texts AS (
    SELECT
        c.PORTFOLIONAME,
        CASE
            WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE)) as asofdate,
        count(*) as text_list,
        count(coalesce(a.CONVERSATIONID, b.CONVERSATIONID)) as texts_sent,
        COUNT(CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_RPCs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH')
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_PTPs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_OTPs,
        text_PTPs + text_OTPs AS text_conversions
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    CROSS JOIN min_dates md
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) >= md.min_record_insert_date
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(DATEADD('day', -1, c.record_insert_date))
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND c."SmsLastAttempt-PHONE" is null
        AND DATE(b.INTERACTION_START_TIME) >= md.min_record_insert_date
    WHERE c.CHANNEL = 'Text'
    GROUP BY c.PORTFOLIONAME, loanstatus, asofdate
),
-- SUBSCRIBER_KEY_MATCHING CTE: Email attribution logic
subscriber_key_matching AS (
    SELECT
        vlcc.CUSTOMER_ID,
        vlcc.LOAN_ID as APPLICATION_ID,
        va.APPLICATION_GUID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT VLCC
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT VA
        ON VA.LOAN_ID::VARCHAR = VLCC.LOAN_ID::VARCHAR
    WHERE VLCC.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    QUALIFY row_number() over (partition by vlcc.CUSTOMER_ID order by ORIGINATION_DATE desc, APPLICATION_STARTED_DATE desc) = 1
),
-- EMAILS_SENT CTE: Email outreach metrics with complete campaign filtering
-- NOTE: Preserves all original email campaign DPD mapping logic from original view
emails_sent AS (
    SELECT
        sum(a.sent) as emails_sent,
        date(a.EVENT_DATE) as ASOFDATE,
        CASE
            WHEN b.status = 'Current' AND to_number(b.dayspastdue) < 3 THEN 'Current'
            WHEN (to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue) < 15) OR
                SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_4-14Days_EM1_0823','GR_Batch_DLQ_PastDue_4-14Days_EM1_1123',
                'COL_Batch_DLQ_PastDue_3Days_EM1_0225','COL_Batch_DLQ_PastDue_5Days_EM2_0225','COL_Batch_DLQ_PastDue_10Days_EM3_0225','COL_Batch_DLQ_PastDue_15-29Days_EM4_0125','COL_Batch_DLQ_PastDue_5Days_EM2_0125',
                'COL_Batch_DLQ_PastDue_10Days_EM3_0125','COL_Batch_DLQ_PastDue_25Days_EM5_0125','COL_Batch_DLQ_PastDue_3Days_EM1_0125','12 GR_Batch_DLQ_PastDue_0-3Days_EM1_0824','GR_Batch_DLQ_PastDue_15-29Days_EM1_0824',
                'GR_Batch_DLQ_PastDue_3Days_EM1_0125','GR_Batch_DLQ_PastDue_Day10_EM1_0824','GR_Batch_DLQ_PastDue_Day25_EM1_0824','GR_Batch_DLQ_PastDue_Day5_EM1_0824')
                OR ((to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue) < 15) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))
                THEN 'DPD3-14'
            WHEN (to_number(b.dayspastdue) >= 15 AND to_number(b.dayspastdue) < 30) OR
                SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_15-29Days_EM1_0823','GR_Batch_DLQ_PastDue_15-29Days_EM1_1123',
                'COL_Batch_DLQ_PastDue_15-29Days_EM4_0225','COL_Batch_DLQ_PastDue_25Days_EM5_0225')
                OR ((to_number(b.dayspastdue) >= 15 AND to_number(b.dayspastdue) < 30) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))
                THEN 'DPD15-29'
            WHEN (to_number(b.dayspastdue) >= 30 AND to_number(b.dayspastdue) < 60) OR
                SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_45Days_EM1_1123','GR_Batch_DLQ_PastDue_45Days_EM1_0823','MKT_Batch_GR_PastDue_45Days_EM5_0523',
                'GR_Batch_DLQ_PastDue_30-59Days_EM1_1123','GR_Batch_DLQ_PastDue_30-59Days_EM1_0823','COL_Batch_DLQ_PastDue_59Days_EM7_0225')
                OR ((to_number(b.dayspastdue) >= 30 AND to_number(b.dayspastdue) < 60) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))
                THEN 'DPD30-59'
            WHEN SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225') THEN 'DPD3-14'
            WHEN (to_number(b.dayspastdue) >= 60 AND to_number(b.dayspastdue) < 90)
                OR (to_number(b.dayspastdue) >= 60 AND to_number(b.dayspastdue) < 90
                    AND SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125',
                    'COL_Batch_DLQ_PastDue_40-60Days_EM6_0225','GR_Batch_DLQ_PastDue_30-60Days_EM1_0824','COL_Batch_DLQ_PastDue_30-60Days_EM6_0225','COL_Batch_DLQ_PastDue_30-60Days_EM5_0125',
                    'GR_Batch_DLQ_PastDue_Day75_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125'))
                THEN 'DPD60-89'
            WHEN (to_number(b.dayspastdue) >= 90
                    AND SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125',
                        'GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123'))
                OR to_number(b.dayspastdue) >= 90
                OR (b.status = 'Charge off' AND SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123',
                    'COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125'))
                OR SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123')
                THEN 'DPD90+'
            WHEN SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_40-60Days_EM6_0225','GR_Batch_DLQ_PastDue_30-60Days_EM1_0824','COL_Batch_DLQ_PastDue_30-60Days_EM6_0225','GR_Batch_DLQ_PastDue_Day75_EM1_0824',
                'COL_Batch_DLQ_PastDue_30-60Days_EM5_0125','COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125')
                THEN 'DPD60-89'
            WHEN b.status = 'Paid in Full' AND SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_0-3Days_EM1_0823','GR_Batch_DLQ_PastDue_0-3Days_EM1_1123')
                THEN 'Current'
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
    INNER JOIN loan_tape_base b
        ON COALESCE(a.DERIVED_PAYOFFUID, c.APPLICATION_GUID) = b.PAYOFFUID
        AND date(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
    GROUP BY b.PORTFOLIONAME, LOANSTATUS, date(a.EVENT_DATE)
    HAVING sum(a.SENT) > 0
),
-- GR_EMAIL_LISTS CTE: GR Email list metrics
gr_email_lists AS (
    SELECT
        count(OL.PAYOFFUID) AS gr_email_list,
        OL.LOAD_DATE as ASOFDATE,
        CASE
            WHEN to_number(LT.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(LT.dayspastdue) >= 3 AND to_number(LT.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(LT.dayspastdue) >= 15 AND to_number(LT.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(LT.dayspastdue) >= 30 AND to_number(LT.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(LT.dayspastdue) >= 60 AND to_number(LT.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(LT.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        LT.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST OL
    INNER JOIN loan_tape_base LT
        ON OL.PAYOFFUID = LT.PAYOFFUID
        AND OL.LOAN_TAPE_ASOFDATE = LT.ASOFDATE
    WHERE OL.SET_NAME = 'GR Email'
        AND OL.SUPPRESSION_FLAG = false
    GROUP BY LT.PORTFOLIONAME, loanstatus, OL.LOAD_DATE
)
-- FINAL SELECT: Aggregate all metrics
SELECT
    dqs.*,
    coalesce(pc.call_list, 0) as call_list,
    coalesce(pc.call_attempted, 0) as call_attempted,
    coalesce(pc.connections, 0) as connections,
    coalesce(pc.voicemails_attempted, 0) as voicemails_attempted,
    coalesce(pc.voicemails_left, 0) as voicemails_left,
    coalesce(pc.RPCs, 0) as RPCs,
    coalesce(pc.PTPs, 0) as PTPs,
    coalesce(pc.OTPs, 0) as OTPs,
    coalesce(pc.conversions, 0) as conversions,
    coalesce(st.text_list, 0) as text_list,
    coalesce(texts_sent, 0) as texts_sent,
    coalesce(text_RPCs, 0) as text_RPCs,
    coalesce(text_PTPs, 0) as text_PTPs,
    coalesce(text_OTPs, 0) as text_OTPs,
    coalesce(text_conversions, 0) as text_conversions,
    coalesce(es.emails_sent, 0) as emails_sent,
    coalesce(el.gr_email_list, 0) as gr_email_list
FROM dqs
LEFT JOIN phone_calls pc
    ON dqs.PORTFOLIONAME = pc.PORTFOLIONAME
    AND dqs.loanstatus = pc.loanstatus
    AND dqs.ASOFDATE = pc.asofdate
LEFT JOIN sent_texts st
    ON dqs.PORTFOLIONAME = st.PORTFOLIONAME
    AND dqs.loanstatus = st.loanstatus
    AND dqs.ASOFDATE = st.asofdate
LEFT JOIN emails_sent es
    ON dqs.PORTFOLIONAME = es.PORTFOLIONAME
    AND dqs.loanstatus = es.loanstatus
    AND dqs.ASOFDATE = es.asofdate
LEFT JOIN gr_email_lists el
    ON dqs.PORTFOLIONAME = el.PORTFOLIONAME
    AND dqs.loanstatus = el.loanstatus
    AND dqs.ASOFDATE = el.asofdate;

-- Step 3: Verify Grants
SHOW GRANTS ON VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;

-- Step 4: Test Query Performance
SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;

-- ==============================================================================
-- POST-DEPLOYMENT VALIDATION
-- ==============================================================================
-- Run qc_validation.sql against production view
-- Monitor performance and data quality
-- Verify email campaign filtering logic is working correctly

-- ==============================================================================
-- ROLLBACK PLAN (if issues arise)
-- ==============================================================================
/*
DROP VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
ALTER VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251002
  RENAME TO VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
*/
