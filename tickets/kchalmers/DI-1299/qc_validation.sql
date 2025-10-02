-- DI-1299: Quality Check - Compare Dev View vs Production View
-- Purpose: Validate that BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
--          matches BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
-- Expected Result: All tests should show PASS with minimal variance (<0.1% for metrics)
use warehouse BUSINESS_INTELLIGENCE_LARGE;
--Test 1: Row Count Comparison
CREATE OR REPLACE TEMP TABLE BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP AS
SELECT * FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
CREATE OR REPLACE TEMP TABLE BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP AS
SELECT * FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;

SELECT
    'Test 1: Row Count Comparison' as test_name,
    dev.row_count as dev_row_count,
    prod.row_count as prod_row_count,
    dev.row_count - prod.row_count as difference,
    CASE
        WHEN dev.row_count = prod.row_count THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM (
    SELECT COUNT(*) as row_count
    FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
) dev
CROSS JOIN (
    SELECT COUNT(*) as row_count
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
) prod;

--Test 2: Date Range Comparison
SELECT
    'Test 2: Date Range Comparison' as test_name,
    dev.min_date as dev_min_date,
    prod.min_date as prod_min_date,
    dev.max_date as dev_max_date,
    prod.max_date as prod_max_date,
    CASE
        WHEN dev.min_date = prod.min_date AND dev.max_date = prod.max_date THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM (
    SELECT MIN(ASOFDATE) as min_date, MAX(ASOFDATE) as max_date
    FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
) dev
CROSS JOIN (
    SELECT MIN(ASOFDATE) as min_date, MAX(ASOFDATE) as max_date
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
) prod;

--Test 3.1: Dev View Duplicate Check
SELECT
    'Test 3.1: Dev View Duplicate Check' as test_name,
    COUNT(*) as duplicate_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM (
    SELECT ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID, COUNT(*) as cnt
    FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
    GROUP BY ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID
    HAVING COUNT(*) > 1
);

--Test 3.2: Prod View Duplicate Check
SELECT
    'Test 3.2: Prod View Duplicate Check' as test_name,
    COUNT(*) as duplicate_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM (
    SELECT ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID, COUNT(*) as cnt
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
    GROUP BY ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID
    HAVING COUNT(*) > 1
);

--Test 4: Metric Sum Comparison (All 19 Numeric Columns)
WITH dev_sums AS (
    SELECT
        SUM(ALL_ACTIVE_LOANS) as sum_all_active_loans,
        SUM(DQ_COUNT) as sum_dq_count,
        SUM(CALL_LIST) as sum_call_list,
        SUM(CALL_ATTEMPTED) as sum_call_attempted,
        SUM(CONNECTIONS) as sum_connections,
        SUM(VOICEMAILS_ATTEMPTED) as sum_voicemails_attempted,
        SUM(VOICEMAILS_LEFT) as sum_voicemails_left,
        SUM(RPCS) as sum_rpcs,
        SUM(PTPS) as sum_ptps,
        SUM(OTPS) as sum_otps,
        SUM(CONVERSIONS) as sum_conversions,
        SUM(TEXT_LIST) as sum_text_list,
        SUM(TEXTS_SENT) as sum_texts_sent,
        SUM(TEXT_RPCS) as sum_text_rpcs,
        SUM(TEXT_PTPS) as sum_text_ptps,
        SUM(TEXT_OTPS) as sum_text_otps,
        SUM(TEXT_CONVERSIONS) as sum_text_conversions,
        SUM(EMAILS_SENT) as sum_emails_sent,
        SUM(GR_EMAIL_LIST) as sum_gr_email_list
    FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
),
prod_sums AS (
    SELECT
        SUM(ALL_ACTIVE_LOANS) as sum_all_active_loans,
        SUM(DQ_COUNT) as sum_dq_count,
        SUM(CALL_LIST) as sum_call_list,
        SUM(CALL_ATTEMPTED) as sum_call_attempted,
        SUM(CONNECTIONS) as sum_connections,
        SUM(VOICEMAILS_ATTEMPTED) as sum_voicemails_attempted,
        SUM(VOICEMAILS_LEFT) as sum_voicemails_left,
        SUM(RPCS) as sum_rpcs,
        SUM(PTPS) as sum_ptps,
        SUM(OTPS) as sum_otps,
        SUM(CONVERSIONS) as sum_conversions,
        SUM(TEXT_LIST) as sum_text_list,
        SUM(TEXTS_SENT) as sum_texts_sent,
        SUM(TEXT_RPCS) as sum_text_rpcs,
        SUM(TEXT_PTPS) as sum_text_ptps,
        SUM(TEXT_OTPS) as sum_text_otps,
        SUM(TEXT_CONVERSIONS) as sum_text_conversions,
        SUM(EMAILS_SENT) as sum_emails_sent,
        SUM(GR_EMAIL_LIST) as sum_gr_email_list
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
)
SELECT
    'Test 4: Metric Sum Comparison' as test_name,
    'ALL_ACTIVE_LOANS' as metric,
    d.sum_all_active_loans as dev_sum,
    p.sum_all_active_loans as prod_sum,
    d.sum_all_active_loans - p.sum_all_active_loans as difference,
    ROUND(ABS((d.sum_all_active_loans - p.sum_all_active_loans) / NULLIF(p.sum_all_active_loans, 0) * 100), 4) as pct_variance,
    CASE WHEN ABS((d.sum_all_active_loans - p.sum_all_active_loans) / NULLIF(p.sum_all_active_loans, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END as result
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'DQ_COUNT', d.sum_dq_count, p.sum_dq_count, d.sum_dq_count - p.sum_dq_count,
    ROUND(ABS((d.sum_dq_count - p.sum_dq_count) / NULLIF(p.sum_dq_count, 0) * 100), 4),
    CASE WHEN ABS((d.sum_dq_count - p.sum_dq_count) / NULLIF(p.sum_dq_count, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'CALL_LIST', d.sum_call_list, p.sum_call_list, d.sum_call_list - p.sum_call_list,
    ROUND(ABS((d.sum_call_list - p.sum_call_list) / NULLIF(p.sum_call_list, 0) * 100), 4),
    CASE WHEN ABS((d.sum_call_list - p.sum_call_list) / NULLIF(p.sum_call_list, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'CALL_ATTEMPTED', d.sum_call_attempted, p.sum_call_attempted, d.sum_call_attempted - p.sum_call_attempted,
    ROUND(ABS((d.sum_call_attempted - p.sum_call_attempted) / NULLIF(p.sum_call_attempted, 0) * 100), 4),
    CASE WHEN ABS((d.sum_call_attempted - p.sum_call_attempted) / NULLIF(p.sum_call_attempted, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'CONNECTIONS', d.sum_connections, p.sum_connections, d.sum_connections - p.sum_connections,
    ROUND(ABS((d.sum_connections - p.sum_connections) / NULLIF(p.sum_connections, 0) * 100), 4),
    CASE WHEN ABS((d.sum_connections - p.sum_connections) / NULLIF(p.sum_connections, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'VOICEMAILS_ATTEMPTED', d.sum_voicemails_attempted, p.sum_voicemails_attempted, d.sum_voicemails_attempted - p.sum_voicemails_attempted,
    ROUND(ABS((d.sum_voicemails_attempted - p.sum_voicemails_attempted) / NULLIF(p.sum_voicemails_attempted, 0) * 100), 4),
    CASE WHEN ABS((d.sum_voicemails_attempted - p.sum_voicemails_attempted) / NULLIF(p.sum_voicemails_attempted, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'VOICEMAILS_LEFT', d.sum_voicemails_left, p.sum_voicemails_left, d.sum_voicemails_left - p.sum_voicemails_left,
    ROUND(ABS((d.sum_voicemails_left - p.sum_voicemails_left) / NULLIF(p.sum_voicemails_left, 0) * 100), 4),
    CASE WHEN ABS((d.sum_voicemails_left - p.sum_voicemails_left) / NULLIF(p.sum_voicemails_left, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'RPCS', d.sum_rpcs, p.sum_rpcs, d.sum_rpcs - p.sum_rpcs,
    ROUND(ABS((d.sum_rpcs - p.sum_rpcs) / NULLIF(p.sum_rpcs, 0) * 100), 4),
    CASE WHEN ABS((d.sum_rpcs - p.sum_rpcs) / NULLIF(p.sum_rpcs, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'PTPS', d.sum_ptps, p.sum_ptps, d.sum_ptps - p.sum_ptps,
    ROUND(ABS((d.sum_ptps - p.sum_ptps) / NULLIF(p.sum_ptps, 0) * 100), 4),
    CASE WHEN ABS((d.sum_ptps - p.sum_ptps) / NULLIF(p.sum_ptps, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'OTPS', d.sum_otps, p.sum_otps, d.sum_otps - p.sum_otps,
    ROUND(ABS((d.sum_otps - p.sum_otps) / NULLIF(p.sum_otps, 0) * 100), 4),
    CASE WHEN ABS((d.sum_otps - p.sum_otps) / NULLIF(p.sum_otps, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'CONVERSIONS', d.sum_conversions, p.sum_conversions, d.sum_conversions - p.sum_conversions,
    ROUND(ABS((d.sum_conversions - p.sum_conversions) / NULLIF(p.sum_conversions, 0) * 100), 4),
    CASE WHEN ABS((d.sum_conversions - p.sum_conversions) / NULLIF(p.sum_conversions, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXT_LIST', d.sum_text_list, p.sum_text_list, d.sum_text_list - p.sum_text_list,
    ROUND(ABS((d.sum_text_list - p.sum_text_list) / NULLIF(p.sum_text_list, 0) * 100), 4),
    CASE WHEN ABS((d.sum_text_list - p.sum_text_list) / NULLIF(p.sum_text_list, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXTS_SENT', d.sum_texts_sent, p.sum_texts_sent, d.sum_texts_sent - p.sum_texts_sent,
    ROUND(ABS((d.sum_texts_sent - p.sum_texts_sent) / NULLIF(p.sum_texts_sent, 0) * 100), 4),
    CASE WHEN ABS((d.sum_texts_sent - p.sum_texts_sent) / NULLIF(p.sum_texts_sent, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXT_RPCS', d.sum_text_rpcs, p.sum_text_rpcs, d.sum_text_rpcs - p.sum_text_rpcs,
    ROUND(ABS((d.sum_text_rpcs - p.sum_text_rpcs) / NULLIF(p.sum_text_rpcs, 0) * 100), 4),
    CASE WHEN ABS((d.sum_text_rpcs - p.sum_text_rpcs) / NULLIF(p.sum_text_rpcs, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXT_PTPS', d.sum_text_ptps, p.sum_text_ptps, d.sum_text_ptps - p.sum_text_ptps,
    ROUND(ABS((d.sum_text_ptps - p.sum_text_ptps) / NULLIF(p.sum_text_ptps, 0) * 100), 4),
    CASE WHEN ABS((d.sum_text_ptps - p.sum_text_ptps) / NULLIF(p.sum_text_ptps, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXT_OTPS', d.sum_text_otps, p.sum_text_otps, d.sum_text_otps - p.sum_text_otps,
    ROUND(ABS((d.sum_text_otps - p.sum_text_otps) / NULLIF(p.sum_text_otps, 0) * 100), 4),
    CASE WHEN ABS((d.sum_text_otps - p.sum_text_otps) / NULLIF(p.sum_text_otps, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'TEXT_CONVERSIONS', d.sum_text_conversions, p.sum_text_conversions, d.sum_text_conversions - p.sum_text_conversions,
    ROUND(ABS((d.sum_text_conversions - p.sum_text_conversions) / NULLIF(p.sum_text_conversions, 0) * 100), 4),
    CASE WHEN ABS((d.sum_text_conversions - p.sum_text_conversions) / NULLIF(p.sum_text_conversions, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'EMAILS_SENT', d.sum_emails_sent, p.sum_emails_sent, d.sum_emails_sent - p.sum_emails_sent,
    ROUND(ABS((d.sum_emails_sent - p.sum_emails_sent) / NULLIF(p.sum_emails_sent, 0) * 100), 4),
    CASE WHEN ABS((d.sum_emails_sent - p.sum_emails_sent) / NULLIF(p.sum_emails_sent, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
UNION ALL
SELECT 'Test 4: Metric Sum Comparison', 'GR_EMAIL_LIST', d.sum_gr_email_list, p.sum_gr_email_list, d.sum_gr_email_list - p.sum_gr_email_list,
    ROUND(ABS((d.sum_gr_email_list - p.sum_gr_email_list) / NULLIF(p.sum_gr_email_list, 0) * 100), 4),
    CASE WHEN ABS((d.sum_gr_email_list - p.sum_gr_email_list) / NULLIF(p.sum_gr_email_list, 0)) < 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM dev_sums d CROSS JOIN prod_sums p
ORDER BY metric;

--Test 5: Sample Row-by-Row Comparison (100 random rows)
WITH sample_keys AS (
    SELECT ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
    ORDER BY RANDOM()
    LIMIT 100
),
dev_sample AS (
    SELECT d.*
    FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP d
    INNER JOIN sample_keys s
        ON d.ASOFDATE = s.ASOFDATE
        AND d.LOANSTATUS = s.LOANSTATUS
        AND d.PORTFOLIONAME = s.PORTFOLIONAME
        AND d.PORTFOLIOID = s.PORTFOLIOID
),
prod_sample AS (
    SELECT p.*
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP p
    INNER JOIN sample_keys s
        ON p.ASOFDATE = s.ASOFDATE
        AND p.LOANSTATUS = s.LOANSTATUS
        AND p.PORTFOLIONAME = s.PORTFOLIONAME
        AND p.PORTFOLIOID = s.PORTFOLIOID
)
SELECT
    'Test 5: Sample Row Comparison (100 random rows)' as test_name,
    COUNT(*) as total_rows,
    SUM(CASE WHEN d.ALL_ACTIVE_LOANS = p.ALL_ACTIVE_LOANS THEN 1 ELSE 0 END) as all_active_loans_match,
    SUM(CASE WHEN d.DQ_COUNT = p.DQ_COUNT THEN 1 ELSE 0 END) as dq_count_match,
    SUM(CASE WHEN d.CALL_LIST = p.CALL_LIST THEN 1 ELSE 0 END) as call_list_match,
    SUM(CASE WHEN d.CALL_ATTEMPTED = p.CALL_ATTEMPTED THEN 1 ELSE 0 END) as call_attempted_match,
    SUM(CASE WHEN d.CONNECTIONS = p.CONNECTIONS THEN 1 ELSE 0 END) as connections_match,
    SUM(CASE WHEN d.VOICEMAILS_ATTEMPTED = p.VOICEMAILS_ATTEMPTED THEN 1 ELSE 0 END) as voicemails_attempted_match,
    SUM(CASE WHEN d.VOICEMAILS_LEFT = p.VOICEMAILS_LEFT THEN 1 ELSE 0 END) as voicemails_left_match,
    SUM(CASE WHEN d.RPCS = p.RPCS THEN 1 ELSE 0 END) as rpcs_match,
    SUM(CASE WHEN d.PTPS = p.PTPS THEN 1 ELSE 0 END) as ptps_match,
    SUM(CASE WHEN d.OTPS = p.OTPS THEN 1 ELSE 0 END) as otps_match,
    SUM(CASE WHEN d.CONVERSIONS = p.CONVERSIONS THEN 1 ELSE 0 END) as conversions_match,
    SUM(CASE WHEN d.TEXT_LIST = p.TEXT_LIST THEN 1 ELSE 0 END) as text_list_match,
    SUM(CASE WHEN d.TEXTS_SENT = p.TEXTS_SENT THEN 1 ELSE 0 END) as texts_sent_match,
    SUM(CASE WHEN d.TEXT_RPCS = p.TEXT_RPCS THEN 1 ELSE 0 END) as text_rpcs_match,
    SUM(CASE WHEN d.TEXT_PTPS = p.TEXT_PTPS THEN 1 ELSE 0 END) as text_ptps_match,
    SUM(CASE WHEN d.TEXT_OTPS = p.TEXT_OTPS THEN 1 ELSE 0 END) as text_otps_match,
    SUM(CASE WHEN d.TEXT_CONVERSIONS = p.TEXT_CONVERSIONS THEN 1 ELSE 0 END) as text_conversions_match,
    SUM(CASE WHEN d.EMAILS_SENT = p.EMAILS_SENT THEN 1 ELSE 0 END) as emails_sent_match,
    SUM(CASE WHEN d.GR_EMAIL_LIST = p.GR_EMAIL_LIST THEN 1 ELSE 0 END) as gr_email_list_match,
    CASE
        WHEN SUM(CASE WHEN
            d.ALL_ACTIVE_LOANS = p.ALL_ACTIVE_LOANS AND
            d.DQ_COUNT = p.DQ_COUNT AND
            d.CALL_LIST = p.CALL_LIST AND
            d.CALL_ATTEMPTED = p.CALL_ATTEMPTED AND
            d.CONNECTIONS = p.CONNECTIONS AND
            d.VOICEMAILS_ATTEMPTED = p.VOICEMAILS_ATTEMPTED AND
            d.VOICEMAILS_LEFT = p.VOICEMAILS_LEFT AND
            d.RPCS = p.RPCS AND
            d.PTPS = p.PTPS AND
            d.OTPS = p.OTPS AND
            d.CONVERSIONS = p.CONVERSIONS AND
            d.TEXT_LIST = p.TEXT_LIST AND
            d.TEXTS_SENT = p.TEXTS_SENT AND
            d.TEXT_RPCS = p.TEXT_RPCS AND
            d.TEXT_PTPS = p.TEXT_PTPS AND
            d.TEXT_OTPS = p.TEXT_OTPS AND
            d.TEXT_CONVERSIONS = p.TEXT_CONVERSIONS AND
            d.EMAILS_SENT = p.EMAILS_SENT AND
            d.GR_EMAIL_LIST = p.GR_EMAIL_LIST
        THEN 1 ELSE 0 END) = COUNT(*) THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM dev_sample d
INNER JOIN prod_sample p
    ON d.ASOFDATE = p.ASOFDATE
    AND d.LOANSTATUS = p.LOANSTATUS
    AND d.PORTFOLIONAME = p.PORTFOLIONAME
    AND d.PORTFOLIOID = p.PORTFOLIOID;

--Test 6.1: Portfolio Distribution Match
SELECT
    'Test 6.1: Portfolio Distribution Match' as test_name,
    COUNT(DISTINCT d.PORTFOLIONAME) as dev_portfolio_count,
    COUNT(DISTINCT p.PORTFOLIONAME) as prod_portfolio_count,
    CASE
        WHEN COUNT(DISTINCT d.PORTFOLIONAME) = COUNT(DISTINCT p.PORTFOLIONAME) THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP d
CROSS JOIN BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP p;

--Test 6.2: Loan Status Distribution Match
SELECT
    'Test 6.2: Loan Status Distribution Match' as test_name,
    COUNT(DISTINCT d.LOANSTATUS) as dev_status_count,
    COUNT(DISTINCT p.LOANSTATUS) as prod_status_count,
    CASE
        WHEN COUNT(DISTINCT d.LOANSTATUS) = COUNT(DISTINCT p.LOANSTATUS) THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP d
CROSS JOIN BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP p;

--Test 7.1: Dev View NULL Check
SELECT
    'Test 7.1: Dev View NULL Check' as test_name,
    SUM(CASE WHEN ASOFDATE IS NULL THEN 1 ELSE 0 END) as null_asofdate,
    SUM(CASE WHEN LOANSTATUS IS NULL THEN 1 ELSE 0 END) as null_loanstatus,
    SUM(CASE WHEN PORTFOLIONAME IS NULL THEN 1 ELSE 0 END) as null_portfolioname,
    SUM(CASE WHEN PORTFOLIOID IS NULL THEN 1 ELSE 0 END) as null_portfolioid,
    CASE
        WHEN SUM(CASE WHEN ASOFDATE IS NULL OR LOANSTATUS IS NULL OR PORTFOLIONAME IS NULL OR PORTFOLIOID IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP;

--Test 7.2: Prod View NULL Check
SELECT
    'Test 7.2: Prod View NULL Check' as test_name,
    SUM(CASE WHEN ASOFDATE IS NULL THEN 1 ELSE 0 END) as null_asofdate,
    SUM(CASE WHEN LOANSTATUS IS NULL THEN 1 ELSE 0 END) as null_loanstatus,
    SUM(CASE WHEN PORTFOLIONAME IS NULL THEN 1 ELSE 0 END) as null_portfolioname,
    SUM(CASE WHEN PORTFOLIOID IS NULL THEN 1 ELSE 0 END) as null_portfolioid,
    CASE
        WHEN SUM(CASE WHEN ASOFDATE IS NULL OR LOANSTATUS IS NULL OR PORTFOLIONAME IS NULL OR PORTFOLIOID IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP;

--Test 8.1: Dev View Data Integrity (DQ_COUNT <= ALL_ACTIVE_LOANS)
SELECT
    'Test 8.1: Dev View Data Integrity (DQ_COUNT <= ALL_ACTIVE_LOANS)' as test_name,
    COUNT(*) as violation_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
WHERE DQ_COUNT > ALL_ACTIVE_LOANS;

--Test 8.2: Prod View Data Integrity (DQ_COUNT <= ALL_ACTIVE_LOANS)
SELECT
    'Test 8.2: Prod View Data Integrity (DQ_COUNT <= ALL_ACTIVE_LOANS)' as test_name,
    COUNT(*) as violation_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP
WHERE DQ_COUNT > ALL_ACTIVE_LOANS;

--Test 9: Rows in Prod but NOT in Dev
SELECT
    'Test 9: Rows in Prod but NOT in Dev' as test_name,
    COUNT(*) as missing_from_dev_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP p
LEFT JOIN BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP d
    ON p.ASOFDATE = d.ASOFDATE
    AND p.LOANSTATUS = d.LOANSTATUS
    AND p.PORTFOLIONAME = d.PORTFOLIONAME
    AND p.PORTFOLIOID = d.PORTFOLIOID
WHERE d.ASOFDATE IS NULL;

--Test 10: Rows in Dev but NOT in Prod
SELECT
    'Test 10: Rows in Dev but NOT in Prod' as test_name,
    COUNT(*) as extra_in_dev_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END as result
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP d
LEFT JOIN BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_TEMP p
    ON d.ASOFDATE = p.ASOFDATE
    AND d.LOANSTATUS = p.LOANSTATUS
    AND d.PORTFOLIONAME = p.PORTFOLIONAME
    AND d.PORTFOLIOID = p.PORTFOLIOID
WHERE p.ASOFDATE IS NULL;
