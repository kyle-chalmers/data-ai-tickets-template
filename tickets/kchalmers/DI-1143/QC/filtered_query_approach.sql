-- Approach 3: Use specific filters to reduce data volume
-- Query by specific application IDs or date ranges

-- First, find recent application IDs from a faster source
WITH recent_apps AS (
    SELECT DISTINCT application_id
    FROM DEVELOPMENT.FRESHSNOW.APPLICANT_CURRENT
    WHERE created_date >= DATEADD('day', -7, CURRENT_DATE())
    LIMIT 10
)
-- Then query the view with these specific IDs
SELECT *
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL
WHERE LEAD_GUID IN (SELECT application_id FROM recent_apps)
LIMIT 100;