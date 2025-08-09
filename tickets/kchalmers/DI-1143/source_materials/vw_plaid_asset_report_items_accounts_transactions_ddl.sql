-- DDL for BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS_TRANSACTIONS

create or replace view VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS_TRANSACTIONS as
     SELECT Record_Create_Datetime
    , Asset_Report_Id
    , Lead_Guid
    , Lead_Id
    , Member_Id
    , Plaid_Token_Id
    , transactions.value:accountId::string AS account_id
    , transactions.value:accountOwner::string AS account_owner
    , transactions.value:amount::string AS transaction_amount
    , NULLIF(transactions.value:category, '[]') AS transaction_category
    , transactions.value:categoryId::string AS transaction_category_id
    , transactions.value:date::string AS transaction_date
    , transactions.value:dateTransacted::string AS date_transacted
    , transactions.value:isoCurrencyCode::string AS transaction_iso_currency_code
    , transactions.value:location AS transaction_location
    , transactions.value:name::string AS transaction_name
    , transactions.value:originalDescription::string AS transaction_original_description
    , transactions.value:paymentMeta AS transaction_payment_metadata
    , transactions.value:paymentMeta:byOrderOf::string AS transaction_by_order_of
    , transactions.value:paymentMeta:payee::string AS transaction_payee
    , transactions.value:paymentMeta:payer::string AS transaction_payer
    , transactions.value:paymentMeta:paymentMethod::string AS transaction_payment_method
    , transactions.value:paymentMeta:paymentProcessor::string AS transaction_payment_processor
    , transactions.value:paymentMeta:ppdId::string AS transaction_ppdId
    , transactions.value:paymentMeta:reason::string AS transaction_reason
    , transactions.value:paymentMeta:referenceNumber::string AS transaction_reference_Number
    , transactions.value:pending::string AS transaction_pending
    , transactions.value:pendingTransactionId::string AS pending_transaction_id
    , transactions.value:transactionId::string AS transaction_id
    , transactions.value:transactionType::string AS transaction_type
    , transactions.value:unofficialCurrencyCode::string AS transaction_unofficial_currency_code
    FROM RAW_DATA_STORE.KAFKA.ext_plaid_asset
    , lateral flatten(input => data_raw:report:items) items
    , lateral flatten(input => items.value:accounts) accounts
    , lateral flatten(input => accounts.value:transactions) transactions;