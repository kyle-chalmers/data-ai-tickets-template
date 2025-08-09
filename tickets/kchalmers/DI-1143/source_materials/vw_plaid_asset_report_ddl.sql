-- DDL for BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT

create or replace view VW_PLAID_ASSET_REPORT as
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
    , data_raw:report AS asset_report
    , data_raw:report:clientReportId::string AS client_report_id
    , data_raw:report:dateGenerated::string AS date_generated
    , data_raw:report:daysRequested::string AS days_requested
     FROM RAW_DATA_STORE.KAFKA.ext_plaid_asset;