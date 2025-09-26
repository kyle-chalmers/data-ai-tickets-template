-- ==============================================================================
-- Field Population Analysis for DI-1272 New Fields
-- ==============================================================================
-- Ticket: DI-1272
-- Purpose: Analyze population rates of representative fields from the 188 new fields
-- Total Records: 372,456 (LMS schema only)
-- ==============================================================================

-- Get total record count for reference
SELECT COUNT(*) as total_records
FROM ARCA.FRESHSNOW.TRANSFORMED_CUSTOM_FIELD_ENTITY_CURRENT cs
JOIN ARCA.FRESHSNOW.LOAN_ENTITY_CURRENT le ON cs.entity_id = le.id
WHERE cs.schema_name = ARCA.config.lms_schema()
  AND le.schema_name = ARCA.config.lms_schema();

-- Analysis of key representative fields from the 188 new fields
WITH field_analysis AS (
    SELECT
        COUNT(*) as total_records,

        -- Bankruptcy fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:BANKRUPTCYBALANCE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:BANKRUPTCYBALANCE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:BANKRUPTCYBALANCE::VARCHAR != 'null'
                   THEN 1 END) as bankruptcy_balance_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:BANKRUPTCYCHAPTER::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:BANKRUPTCYCHAPTER::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:BANKRUPTCYCHAPTER::VARCHAR != 'null'
                   THEN 1 END) as bankruptcy_chapter_count,

        -- Fraud investigation fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:FRAUDJIRATICKET1::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET1::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET1::VARCHAR != 'null'
                   THEN 1 END) as fraud_jira_1_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:FRAUDJIRATICKET2::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET2::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET2::VARCHAR != 'null'
                   THEN 1 END) as fraud_jira_2_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:FRAUDJIRATICKET10::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET10::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:FRAUDJIRATICKET10::VARCHAR != 'null'
                   THEN 1 END) as fraud_jira_10_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:FRAUDSTATUSRESULTS1::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:FRAUDSTATUSRESULTS1::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:FRAUDSTATUSRESULTS1::VARCHAR != 'null'
                   THEN 1 END) as fraud_status_1_count,

        -- Attorney fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:ATTORNEYORGANIZATION::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:ATTORNEYORGANIZATION::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:ATTORNEYORGANIZATION::VARCHAR != 'null'
                   THEN 1 END) as attorney_org_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:ATTORNEYPHONE2::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:ATTORNEYPHONE2::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:ATTORNEYPHONE2::VARCHAR != 'null'
                   THEN 1 END) as attorney_phone2_count,

        -- SCRA/Military fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:ACTIVEDUTYENDDATE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:ACTIVEDUTYENDDATE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:ACTIVEDUTYENDDATE::VARCHAR != 'null'
                   THEN 1 END) as active_duty_end_count,

        -- DCA fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:DCASTARTDATE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:DCASTARTDATE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:DCASTARTDATE::VARCHAR != 'null'
                   THEN 1 END) as dca_start_count,

        -- Low business value fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:REPURPOSE2::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:REPURPOSE2::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:REPURPOSE2::VARCHAR != 'null'
                   THEN 1 END) as repurpose2_count,

        -- Well-populated fields
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:USCITIZENSHIP::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:USCITIZENSHIP::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:USCITIZENSHIP::VARCHAR != 'null'
                   THEN 1 END) as citizenship_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:LATESTBUREAUSCORE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:LATESTBUREAUSCORE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:LATESTBUREAUSCORE::VARCHAR != 'null'
                   THEN 1 END) as bureau_score_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:HAPPYSCORE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:HAPPYSCORE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:HAPPYSCORE::VARCHAR != 'null'
                   THEN 1 END) as happy_score_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:"10DAYPAYOFF"::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:"10DAYPAYOFF"::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:"10DAYPAYOFF"::VARCHAR != 'null'
                   THEN 1 END) as ten_day_payoff_count,
        COUNT(CASE WHEN CUSTOM_FIELD_VALUES:LOANMODEFFECTIVEDATE::VARCHAR IS NOT NULL
                        AND CUSTOM_FIELD_VALUES:LOANMODEFFECTIVEDATE::VARCHAR != ''
                        AND CUSTOM_FIELD_VALUES:LOANMODEFFECTIVEDATE::VARCHAR != 'null'
                   THEN 1 END) as loan_mod_effective_count

    FROM ARCA.FRESHSNOW.TRANSFORMED_CUSTOM_FIELD_ENTITY_CURRENT cs
    JOIN ARCA.FRESHSNOW.LOAN_ENTITY_CURRENT le ON cs.entity_id = le.id
    WHERE cs.schema_name = ARCA.config.lms_schema()
      AND le.schema_name = ARCA.config.lms_schema()
)

-- Results formatted with population percentages and categories
SELECT
    total_records,
    field_name,
    non_null_count,
    ROUND((non_null_count::FLOAT / total_records::FLOAT) * 100, 4) as population_percentage,
    CASE
        WHEN ROUND((non_null_count::FLOAT / total_records::FLOAT) * 100, 4) = 0.0 THEN 'NO_DATA'
        WHEN ROUND((non_null_count::FLOAT / total_records::FLOAT) * 100, 4) < 0.1 THEN 'NEAR_NULL'
        WHEN ROUND((non_null_count::FLOAT / total_records::FLOAT) * 100, 4) < 1.0 THEN 'LOW_POPULATION'
        WHEN ROUND((non_null_count::FLOAT / total_records::FLOAT) * 100, 4) < 10.0 THEN 'MODERATE_POPULATION'
        ELSE 'WELL_POPULATED'
    END as population_category
FROM (
    -- Fields with no data (0.0%)
    SELECT total_records, 'BANKRUPTCY_BALANCE' as field_name, bankruptcy_balance_count as non_null_count FROM field_analysis
    UNION ALL SELECT total_records, 'ATTORNEY_ORGANIZATION', attorney_org_count FROM field_analysis
    UNION ALL SELECT total_records, 'ATTORNEY_PHONE_2', attorney_phone2_count FROM field_analysis
    UNION ALL SELECT total_records, 'ACTIVE_DUTY_END_DATE', active_duty_end_count FROM field_analysis
    UNION ALL SELECT total_records, 'DCA_START_DATE', dca_start_count FROM field_analysis
    UNION ALL SELECT total_records, 'REPURPOSE_2', repurpose2_count FROM field_analysis

    -- Fields with minimal data
    UNION ALL SELECT total_records, 'FRAUD_JIRA_TICKET_10', fraud_jira_10_count FROM field_analysis
    UNION ALL SELECT total_records, 'FRAUD_JIRA_TICKET_2', fraud_jira_2_count FROM field_analysis
    UNION ALL SELECT total_records, 'FRAUD_JIRA_TICKET_1', fraud_jira_1_count FROM field_analysis
    UNION ALL SELECT total_records, 'FRAUD_STATUS_RESULTS_1', fraud_status_1_count FROM field_analysis

    -- Fields with moderate data
    UNION ALL SELECT total_records, 'TEN_DAY_PAYOFF', ten_day_payoff_count FROM field_analysis
    UNION ALL SELECT total_records, 'BANKRUPTCY_CHAPTER', bankruptcy_chapter_count FROM field_analysis
    UNION ALL SELECT total_records, 'LOAN_MOD_EFFECTIVE_DATE', loan_mod_effective_count FROM field_analysis
    UNION ALL SELECT total_records, 'HAPPY_SCORE', happy_score_count FROM field_analysis

    -- Fields with high population
    UNION ALL SELECT total_records, 'LATEST_BUREAU_SCORE', bureau_score_count FROM field_analysis
    UNION ALL SELECT total_records, 'US_CITIZENSHIP', citizenship_count FROM field_analysis
) field_results
ORDER BY population_percentage ASC, field_name;