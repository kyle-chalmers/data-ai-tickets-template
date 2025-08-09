-- DDL for BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS

create or replace view VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS as
     SELECT Record_Create_Datetime
    , Asset_Report_Id
    , Lead_Guid
    , Lead_Id
    , Member_Id
    , Plaid_Token_Id
    , data_raw:schema_version::string AS schema_version
    , data_raw:timestamp::string AS asset_report_timestamp
    , data_raw:prev_asset_report_id::string AS prev_asset_report_id
    -- report
    , data_raw:report:clientReportId::string AS client_report_id
    , data_raw:report:dateGenerated::string AS date_generated
    , data_raw:report:daysRequested::string AS days_requested
    , items.value:dateLastUpdated::string AS date_last_updated
    , items.value:institutionId::string AS institution_id
    , items.value:institutionName::string AS institution_name
    , items.value:itemId::string AS item_id
    -- accounts
    , accounts.value:accountId::string AS account_id
    , accounts.value:daysAvailable::string AS days_available
    , NULLIF(accounts.value:historicalBalances::string, '[]') AS historical_balances
    , accounts.value:mask::string AS account_mask
    , accounts.value:name::string AS account_name
    , accounts.value:officialName::string AS account_official_name
    , accounts.value:subtype::string AS account_subtype
    , NULLIF(accounts.value:transactions::string, '[]') AS account_transactions
    , accounts.value:type::string AS account_type
    , accounts.value:balances:available::string AS account_balances_available
    , accounts.value:balances:current::float AS account_balances_current
    , accounts.value:balances:isoCurrencyCode::string AS account_balances_isoCurrencyCode
    , accounts.value:balances:unofficialCurrencyCode::string AS account_balances_unofficialCurrencyCode
    , accounts.value:owners AS account_owners
    FROM RAW_DATA_STORE.KAFKA.ext_plaid_asset
    , lateral flatten(input => data_raw:report:items) items
    , lateral flatten(input => items.value:accounts) accounts;