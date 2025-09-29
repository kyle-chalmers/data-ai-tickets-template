-- Date filter variable: 2 years ago from today
SET funnel_date_filter = (SELECT DATEADD('year', -2, CURRENT_DATE())::VARCHAR);

with cte_cls_stage as (
        select
            ast.PAYOFFUID
            , ast.CREATEDATLOCAL
            , ast.APPLICATION_STARTED_COUNT
            , ast.FIRST_APPLIED_DATE
            , ast.FIRST_OFFER_SHOWN_DATE
            , ast.FIRST_OFFER_ACCEPTED_DATE
            , ast.LAST_FUNDED_DATE
            , ast.LOAN_INTENT
            , ast.LAST_TOUCH_UTM_CHANNEL_GROUPING
            , ast.SELECTED_OFFER_AMOUNT
            , ast.APPLICATION_STARTED -- BI-2774
            , ast.FIRST_PRE_FUNDING_DATE -- BI-2774
            , app.ORIGINATION_FEE
            , app.LOAN_PREMIUMAMOUNT
            , lt.ORIGINATIONFEE
            , lt.PREMIUMPAID
            , lt.ORIGINATIONFEE + lt.PREMIUMPAID AS TOTAL_REVENUE
            , lt.LOANAMOUNT
           -- , app.ID AS APPLICATION_ID
            , (sum(iff(hist.HK_H_APPL is not null, 1, 0)) > 0)::int as Application_Started_HK_H_APPL
            , (sum(iff(hist.NEWVALUE = 'Default Documents', 1, 0))::int > 0)::int as Applied
            , (sum(iff(hist.NEWVALUE = 'offer_shown', 1, 0)) > 0)::int as Offer_Shown
            , (sum(iff(hist.NEWVALUE = 'offer_accepted', 1, 0)) > 0)::int as Offer_Accepted
            , (sum(iff(hist.NEWVALUE = 'docusign_loan_docs_complete', 1, 0)) > 0)::int as Prefunded
            , (sum(iff(hist.NEWVALUE = 'funded', 1, 0)) > 0)::int as Funded

        from BUSINESS_INTELLIGENCE.DATA_STORE.MVW_APPL_STATUS_TRANSITION ast
            left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
                on ast.PAYOFFUID = app.PAYOFF_UID
            left join BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_APPL_HISTORY hist
                on hist.HK_H_APPL = app.HK_H_APPL
            left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE lt
                on ast.PAYOFFUID = lt.PAYOFFUID
       where CREATEDATLOCAL >= $funnel_date_filter
       --where CREATEDATLOCAL >= '2022-12-31'


        group by
            ast.PAYOFFUID
            , ast.CREATEDATLOCAL
            ,ast.APPLICATION_STARTED_COUNT
            ,ast.FIRST_APPLIED_DATE
            ,ast.FIRST_OFFER_SHOWN_DATE
            ,ast.FIRST_OFFER_ACCEPTED_DATE
            ,ast.LAST_FUNDED_DATE
            ,ast.LOAN_INTENT
            ,ast.LAST_TOUCH_UTM_CHANNEL_GROUPING
            , ast.SELECTED_OFFER_AMOUNT
            , ast.APPLICATION_STARTED -- BI-2774
            , ast.FIRST_PRE_FUNDING_DATE -- BI-2774
            , app.ORIGINATION_FEE
            , app.LOAN_PREMIUMAMOUNT
            , lt.ORIGINATIONFEE
            , lt.PREMIUMPAID
            , lt.ORIGINATIONFEE + lt.PREMIUMPAID
            , lt.LOANAMOUNT
          --  , app.ID
)

--     select
--         *
--         , Prefunded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Prefunded_Origination
--         , Funded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Funded_Origination
--         , Prefunded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Prefunded_Revenue
--         , Funded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Funded_Revenue
--         , current_timestamp as LAST_UPDATED
--        -- , 'CLS' AS SOURCE
--     from cte
-- ;


, cte_los_stage as (
    select
        lt.APPLICATION_GUID as PAYOFFUID
        ,CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC)  AS CREATEDATLOCAL
       -- ,FIRST_STARTED_DATETIME -- test; remove
        -- ,CASE  ---- gives 100% applied rate in the dashboard
        --     WHEN lead.utm_medium = 'PARTNER'
        --     THEN IFF(wip.selected_offer_amount is not null, 1, 0)
        --     ELSE IFF(app_pii.FIRST_NAME IS NOT NULL, 1, 0)
        -- END AS APPLICATION_STARTED_COUNT
        ,IFF(lead.utm_medium = 'PARTNER' and wip.first_affiliate_landed_datetime IS NULL, 0, 1) AS APPLICATION_STARTED_COUNT -- this logic may need to be updated
        ,wip.FIRST_APPLIED_DATETIME AS FIRST_APPLIED_DATE
        ,wip.FIRST_OFFERS_SHOWN_DATETIME AS FIRST_OFFER_SHOWN_DATE
        ,wip.FIRST_OFFER_SELECTED_DATETIME as FIRST_OFFER_ACCEPTED_DATE
        ,wip.LAST_ORIGINATED_DATETIME as LAST_FUNDED_DATE
        ,lead.LOAN_INTENT as LOAN_INTENT  -- need to find loan_intent
        ,lead.LAST_TOUCH_UTM_CHANNEL_GROUPING
        ,wip.SELECTED_OFFER_AMOUNT
        ,wip.FIRST_APPLIED_DATETIME as APPLICATION_STARTED
        ,wip.FIRST_PREFUNDING_DATETIME as FIRST_PRE_FUNDING_DATE
        ,ZEROIFNULL(lt.ORIGINATION_FEE) as ORIGINATION_FEE
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) as LOAN_PREMIUMAMOUNT
        ,ZEROIFNULL(lt.ORIGINATION_FEE) as ORIGINATIONFEE
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) as PREMIUMPAID
        ,ZEROIFNULL(lt.ORIGINATION_FEE + lt.PREMIUM_AMOUNT) as TOTAL_REVENUE --ORIGINATIONFEE + lt.PREMIUMPAID
        ,ZEROIFNULL(lt.AMOUNT) as LOANAMOUNT

        -- ,APP_HIST.APPLICATION_ID

        ,(sum(iff(APP_HIST.APPLICATION_ID is not null, 1, 0)) > 0)::int as Application_Started_HK_H_APPL
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('Default Documents', 'Applied'), 1, 0))::int > 0)::int as Applied
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('offer_shown', 'Offers Shown'), 1, 0)) > 0)::int as Offer_Shown
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('offer_accepted', 'Offer Selected'), 1, 0)) > 0)::int as Offer_Accepted
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('docusign_loan_docs_complete', 'Loan Docs Completed'), 1, 0)) > 0)::int as Prefunded
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('funded', 'Originated'), 1, 0)) > 0)::int as Funded

       -- , wip.source
    from
        BUSINESS_INTELLIGENCE.analytics.VW_APPLICATION_STATUS_TRANSITION_WIP wip
        left join business_intelligence.analytics.vw_application app
            on wip.application_id = app.application_id
        left join BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT lt
            on wip.APPLICATION_ID = lt.LOAN_ID
        left join BUSINESS_INTELLIGENCE.ANALYTICS.VW_LEAD lead
            on lt.APPLICATION_GUID = lead.LEAD_GUID
        left join BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_STATUS_HISTORY APP_HIST
            ON APP_HIST.APPLICATION_ID = WIP.APPLICATION_ID
        left join business_intelligence.analytics_pii.vw_application_pii app_pii
            on wip.application_id = app_pii.application_id
        where
            lt.APPLICATION_GUID is not null
            and APP_HIST.SOURCE = 'LOANPRO'
            and CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC) >= $funnel_date_filter
            -- -- handle dupes in cls
            -- and lt.APPLICATION_GUID not in (
            --                                 select PAYOFFUID
            --                                 from cte_cls_stage

            -- )

    group by
        lt.APPLICATION_GUID
        ,CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC)
       -- ,FIRST_STARTED_DATETIME -- test; remove
        -- ,CASE
        --     WHEN lead.utm_medium = 'PARTNER'
        --     THEN IFF(wip.selected_offer_amount is not null, 1, 0)
        --     ELSE IFF(app_pii.FIRST_NAME IS NOT NULL, 1, 0)
        -- END
        ,IFF(lead.utm_medium = 'PARTNER' and wip.first_affiliate_landed_datetime IS NULL, 0, 1)
        ,wip.FIRST_APPLIED_DATETIME
        ,wip.FIRST_OFFERS_SHOWN_DATETIME
        ,wip.FIRST_OFFER_SELECTED_DATETIME
        ,wip.LAST_ORIGINATED_DATETIME
        ,lead.LOAN_INTENT   -- need to find loan_intent
        ,lead.LAST_TOUCH_UTM_CHANNEL_GROUPING
        ,wip.SELECTED_OFFER_AMOUNT
        ,wip.FIRST_APPLIED_DATETIME
        ,wip.FIRST_PREFUNDING_DATETIME
        ,ZEROIFNULL(lt.ORIGINATION_FEE)
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT)
        ,ZEROIFNULL(lt.ORIGINATION_FEE)
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT)
        ,ZEROIFNULL(lt.ORIGINATION_FEE + lt.PREMIUM_AMOUNT) --ORIGINATIONFEE + lt.PREMIUMPAID
        ,ZEROIFNULL(lt.AMOUNT)

)

, cte_union_all as (
    select *, 'cls' as source
    from cte_cls_stage
    union all
    select *, 'los' as source
    from cte_los_stage
    qualify row_number()
                over ( partition by payoffuid
                            order by  GREATEST_IGNORE_NULLS(FIRST_APPLIED_DATE, FIRST_OFFER_SHOWN_DATE, FIRST_OFFER_ACCEPTED_DATE, LAST_FUNDED_DATE, APPLICATION_STARTED, FIRST_PRE_FUNDING_DATE) ) = 1 -- 1 is the latest date of all these fields
)

    select
        * exclude(source)
        , Prefunded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Prefunded_Origination
        , Funded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Funded_Origination
        , Prefunded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Prefunded_Revenue
        , Funded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Funded_Revenue
        , current_timestamp as LAST_UPDATED
       -- , 'CLS' AS SOURCE
    from cte_union_all