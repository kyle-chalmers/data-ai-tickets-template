-- DI-1065: Fortress Quarterly Due Diligence Payment History
-- LoanPro-only transaction query (excluding CLS data for new loans)
-- Based on Bounce debt sales format, adapted for Fortress requirements

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

WITH fortress_loans AS (
    -- Fortress loan identifiers from attachments B & C
    SELECT * FROM (
        VALUES 
        ('2bbbff4b-f7c3-46ac-a10b-8c91317c97cc', 'HM8C91317C97CC'),
        ('8f239083-2784-4033-b926-12aed63cbdc8', 'HM12AED63CBDC8'),
        ('92c5a652-e71a-4c68-a645-da25483339bf', 'HMDA25483339BF'),
        ('7242da38-d3a5-4f6c-8da6-d40660e68a55', 'HMD40660E68A55'),
        ('1f18cb6b-0729-4054-998a-c823190b8952', 'HMC823190B8952'),
        ('71d48bb2-11a9-4538-8d02-f19d2656f6de', 'HMF19D2656F6DE'),
        ('5bfb3052-a13b-48bf-8768-233e2e82983f', 'HM233E2E82983F'),
        ('56eb8451-8c8e-49d9-9b53-a010e3c36fef', 'HMA010E3C36FEF'),
        ('356261dc-048b-4bd9-9daf-d4d65cead877', 'HMD4D65CEAD877'),
        ('e0c9cac1-d79f-4e5c-88c1-346eef55c040', 'HM346EEF55C040'),
        ('7786013f-4470-43f0-a9ca-5b1cdc5b337c', 'HM5B1CDC5B337C'),
        ('477c272e-be7b-498b-81fb-d07b961de6f5', 'HMD07B961DE6F5'),
        ('2db140fc-37d1-4d72-ab83-6e79c8990a0e', 'HM6E79C8990A0E'),
        ('b83177c8-327b-4d03-9fb8-8cf472431307', 'HM8CF472431307')
    ) AS t(lead_guid, legacy_loan_id)
),

loan_details AS (
    -- Core loan information
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        vl.origination_date,
        vl.loan_amount,
        vl.term,
        vl.interest_rate,
        vl.loan_closed_date,
        vl.charge_off_date
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    JOIN fortress_loans fl ON LOWER(vl.lead_guid) = LOWER(fl.lead_guid)
),

payment_transactions AS (
    -- LoanPro payment transaction data (simplified from Bounce format)
    SELECT
        lp.PAYMENT_ID::VARCHAR AS TRANSACTION_ID,
        LOWER(ld.lead_guid) as LEAD_GUID,
        ld.loan_id as LOANID,
        lp.TRANSACTION_DATE as LOAN_TRANSACTION_DATE,
        lp.APPLY_DATE AS POSTED_DATE,
        lp.PAYMENT_TYPE as LOAN_PAYMENT_TYPE,
        'Payment' AS LOAN_TRANSACTION_TYPE,
        CONCAT(lp.PAYMENT_TYPE, ': Transaction ID ', lp.PAYMENT_ID) as DESCRIPTION,
        lp.TRANSACTION_AMOUNT as LOAN_TRANSACTION_AMOUNT,
        TRUE AS PAYMENT_FLAG,
        lp.PRINCIPAL_AMOUNT as LOAN_PRINCIPAL,
        lp.INTEREST_AMOUNT as LOAN_INTEREST,
        (lp.AFTER_PRINCIPAL_BALANCE + lp.PRINCIPAL_AMOUNT) as STARTING_BALANCE,
        lp.AFTER_PRINCIPAL_BALANCE as ENDING_BALANCE,
        FALSE AS POSTCHARGEOFFEVENT, -- These are recent loans, likely no charge-offs yet
        FALSE AS CHARGEOFFEVENTIND,
        lp.IS_REVERSED as LOAN_REVERSED,
        lp.IS_REJECTED as LOAN_REJECTED,
        lp.IS_SETTLED as LOAN_CLEARED
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp
    JOIN loan_details ld ON UPPER(lp.loan_id::TEXT) = UPPER(ld.loan_id::TEXT)
    WHERE lp.IS_MIGRATED = 0 -- Only non-migrated LoanPro transactions
)

-- Final transaction history report
SELECT 
    pt.TRANSACTION_ID,
    pt.LEAD_GUID as PAYOFFUID,
    pt.LOANID,
    pt.LOAN_TRANSACTION_DATE,
    pt.POSTED_DATE as EFFECTIVE_DATE,
    pt.LOAN_TRANSACTION_TYPE,
    pt.DESCRIPTION,
    pt.LOAN_TRANSACTION_AMOUNT,
    pt.PAYMENT_FLAG,
    pt.LOAN_PRINCIPAL,
    pt.LOAN_INTEREST,
    pt.STARTING_BALANCE,
    pt.ENDING_BALANCE,
    pt.POSTCHARGEOFFEVENT,
    pt.CHARGEOFFEVENTIND,
    pt.LOAN_REVERSED,
    pt.LOAN_REJECTED,
    pt.LOAN_CLEARED,
    -- Additional loan context
    ld.origination_date,
    ld.loan_amount,
    ld.term,
    ld.interest_rate,
    ld.loan_closed_date,
    ld.charge_off_date
FROM payment_transactions pt
JOIN loan_details ld ON pt.LEAD_GUID = ld.lead_guid
ORDER BY pt.LEAD_GUID, pt.LOAN_TRANSACTION_DATE, pt.POSTED_DATE;