/***********************************************************************************************************************
Original Phone Dynamic Table DDL
Retrieved: 2025-08-20
Source: BUSINESS_INTELLIGENCE.PII.DT_LKP_PHONE_TO_PAYOFFUID_MATCH

Note: This is the original dynamic table definition before optimization
***********************************************************************************************************************/

create or replace dynamic table DT_LKP_PHONE_TO_PAYOFFUID_MATCH(
	PHONE,
	PAYOFFUID,
	IS_LOAN,
	FIRST_POSSIBLE_CONTACT_DATE,
	LAST_POSSIBLE_CONTACT_DATE
) target_lag = '3 days' refresh_mode = AUTO initialize = ON_CREATE warehouse = BUSINESS_INTELLIGENCE
 as
/*Create Date: 2024-03-08
Author: Kyle Chalmers
Description: Created as a result of this ticket: https://happymoneyinc.atlassian.net/browse/DI-113. The purpose of this table is designing the matching table for PayoffUIDs and phone numbers. Please note all PHONE fields are all 10 digits, OR MORE WITH the area code IF they ARE foreign, and when joining to other phones, they need to follow the same rules as well. There are 3 rules for this table:
An phone has a 1:1 relationship with a PayoffUID, meaning that the phone only is seen once for that single PayoffUID.
An phone has a 1:Many relationship with PayoffUIDs, meaning that the same phone is associated with multiple PayoffUIDs.
Data for PayoffUIDs associated with loans will take precedence over data for PayoffUIDs associated with leads.
For #2 in the list, the two fields FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE are created to utilize when joining to interaction data, so interactions happen between those bounds. If there is a NULL value for that column, it means there is no boundary. If there are multiple loans associated with the same phone, the latest created PayoffUID will have a NULL for LAST_POSSIBLE_CONTACT_DATE, and the earliest created PayoffUID will have a NULL value for FIRST_POSSIBLE_CONTACT_DATE.
For #3 in the list, all phones that are associated with loans, will be associated with those PayoffUIDs, before any others. So if those phones are found to be associated with PayoffUIDs that are loans, then they will not be matched to any PayoffUIDs that are for leads that never turned into loans.

The query is comprised of 3 main data sources from BUSINESS_INTELLIGENCE.PII :

VW_CUSTOMER_INFO
VW_APPLICATION_PII
VW_LEAD_MASTER_PII_UNIQUE
Please note that this data still should be secondary to any list data generated on particular days, as that data will be able to match to Genesys using the inin-outbound-id, utilizing the export from Genesys. However, currently, there are no lists generated that utilize phone, as they only use phone number.

TODO: INVESTIGATE THE POSSIBILITY OF UTILIZING VW_APPLICATION_PII WITH 1:MANY PHONE TO PAYOFFUIDS RELATIONSHIPS*/
-- -- -- -- -- -- -- -- -- FINAL PHONE TABLE -- -- -- -- -- -- -- -- --
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO BASE -- -- -- --
-- Please note VW_CUSTOMER_INFO only contains loans within the view, hence the TRUE AS IS_LOAN field.
WITH LKP_PHONE_LOAN_1_TO_1_MATCHING_CUST_INFO AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_1_TO_1_MATCHING_CUST_INFO EXPLANATION
  This CTE is derived from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO to get the loans that have a 1:1 relationship with.
  phones, meaning that each phone is associated with one PayoffUID.
************************************************************************************************************************/
(SELECT --KEY: ensure phones are all 10 digits, OR MORE WITH the area code IF they ARE foreign
IFF(LEN(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) = 11 AND LEFT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),1) = 1, RIGHT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),10), regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) AS PHONE,
a.PAYOFFUID,
TRUE AS IS_LOAN,
NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a
-- KEY: Filter criteria to ensure we are only getting phones that have 1:1 relationship with PayoffUIDs
where PHONE in
(select IFF(LEN(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),10),
regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) AS PHONE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a WHERE PHONE IS NOT NULL group by PHONE having count(*) = 1))
,LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO EXPLANATION
  This CTE is derived from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO to get the loans that do NOT have a 1:1 relationship with.
  phones, meaning that each phone is associated with multiple PayoffUIDs. It matches these loans to loan tape, to get their
  closed date, which will serve as a boundary in the following queries.
************************************************************************************************************************/
(SELECT
IFF(LEN(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),10),
regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) AS PHONE,
a.PAYOFFUID,
TRUE AS IS_LOAN,
T.LOANCLOSEDDATE AS END_DATE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a
LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE T ON A.PAYOFFUID = T.PAYOFFUID
-- KEY: Filter criteria to ensure we are only getting phones that have 1:1 relationship with PayoffUIDs
where PHONE in
(select IFF(LEN(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(a.PHONENUMBER, '[^[:digit:]]', ''),10),
regexp_replace(a.PHONENUMBER, '[^[:digit:]]', '')) AS PHONE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a WHERE PHONE IS NOT NULL group by PHONE having count(*) > 1))
,CUST_INFO_CONTACT_DATES_FIRST_STAGE AS
/***********************************************************************************************************************
 CUST_INFO_CONTACT_DATES_FIRST_STAGE EXPLANATION
  For the phones associated with multiple PayoffUIDs from LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO, it uses the the
  Loan Close Date with LAG functions and logic to derive the first stage of date boundaries for interactions associated
  with the phone and loans.
************************************************************************************************************************/
(SELECT
    A.PHONE,
    A.PAYOFFUID,
    A.IS_LOAN,
    A.END_DATE,
    -- If there is another loan after this one, obtain its end date
    LAG(A.END_DATE) OVER (PARTITION BY A.PHONE ORDER BY A.END_DATE DESC) AS NEXT_END_DATE,
    -- If there was a loan before this one, take its end date + 1 to make it the first possible contact date
    DATEADD('day',1,(LAG(A.END_DATE) OVER (PARTITION BY A.PHONE ORDER BY A.END_DATE))) AS FIRST_POSSIBLE_CONTACT_DATE,
    -- If there is no next end date, and the first possible contact date is not null, then this is the last loan for this
    -- phone, so there should be no last contact date. Otherwise, it should have a last possible contact date.
    IFF(NEXT_END_DATE IS NULL AND FIRST_POSSIBLE_CONTACT_DATE IS NOT NULL, NULL, A.END_DATE) AS LAST_POSSIBLE_CONTACT_DATE
    FROM LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO A)
,CUST_INFO_CONTACT_DATES_FINAL_STAGE AS
/***********************************************************************************************************************
 CUST_INFO_CONTACT_DATES_FINAL_STAGE EXPLANATION
  This builds off of CUST_INFO_CONTACT_DATES_FIRST_STAGE to ensure all data is correctly presented to be matched to the
  interaction data from Genesys.
************************************************************************************************************************/
(SELECT A.PHONE,
PAYOFFUID,
IS_LOAN,
FIRST_POSSIBLE_CONTACT_DATE,
-- If there is a loan that comes after the current loan, then we need to ensure that this loan has its close date as the
-- last possible contact date.
IFF((LAG(A.FIRST_POSSIBLE_CONTACT_DATE) OVER (PARTITION BY A.PHONE ORDER BY A.END_DATE DESC)) IS NOT NULL
           AND LAST_POSSIBLE_CONTACT_DATE IS NULL,
           END_DATE,LAST_POSSIBLE_CONTACT_DATE) AS LAST_POSSIBLE_CONTACT_DATE
    FROM CUST_INFO_CONTACT_DATES_FIRST_STAGE A
-- There should not be any loans where first possible contact date, and last possible contact date, equal each other
-- from this section.
WHERE IFNULL(FIRST_POSSIBLE_CONTACT_DATE,'1999-02-01') <> IFNULL(LAST_POSSIBLE_CONTACT_DATE,'1999-02-01'))
,FULL_LKP_PHONE_LOAN_MATCHING_CUST_INFO AS (
/***********************************************************************************************************************
 FULL_LKP_PHONE_LOAN_MATCHING_CUST_INFO EXPLANATION
  Bring the data together in a union. All 1:1s will have NULLs for FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE
  while all 1:manys will have at least 1 value populated for FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE.
************************************************************************************************************************/
( SELECT A.PHONE, A.PAYOFFUID, A.IS_LOAN, A.FIRST_POSSIBLE_CONTACT_DATE, A.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_PHONE_LOAN_1_TO_1_MATCHING_CUST_INFO A
UNION SELECT B.PHONE, B.PAYOFFUID, B.IS_LOAN, B.FIRST_POSSIBLE_CONTACT_DATE, B.LAST_POSSIBLE_CONTACT_DATE
FROM CUST_INFO_CONTACT_DATES_FINAL_STAGE B))
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_APPLICATION_PII BASE -- -- -- --
-- Please note only 1:1 relationships are taken from VW_APPLICATION_PII to simplify the query
-- and the rest of the 1:many relationships are pulled from VW_LEAD_MASTER_PII_UNIQUE.
,EXCLUDE_CUST_INFO_FROM_APP AS
/***********************************************************************************************************************
 EXCLUDE_CUST_INFO_FROM_APP EXPLANATION
  This CTE excludes any phones that were identified from VW_CUSTOMER_INFO to ensure there will be no repeats evaluated.
************************************************************************************************************************/
(SELECT IFF(LEN(regexp_replace(b.PHONE, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),10),
regexp_replace(b.PHONE, '[^[:digit:]]', '')) as PHONE,
b.PAYOFF_UID AS PAYOFFUID
from BUSINESS_INTELLIGENCE.PII.VW_APPLICATION_PII b
left join FULL_LKP_PHONE_LOAN_MATCHING_CUST_INFO a on a.PHONE = IFF(LEN(regexp_replace(b.PHONE, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),10),
regexp_replace(b.PHONE, '[^[:digit:]]', ''))
where a.PHONE is null)
,LKP_PHONE_LOAN_1_TO_1_MATCHING_APP AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_1_TO_1_MATCHING_APP EXPLANATION
  This CTE is derived from EXCLUDE_CUST_INFO_FROM_APP CTE to get the loans that have a 1:1 relationship with.
  phones, meaning that each phone is associated with one PayoffUID, using PII from their application.
************************************************************************************************************************/
(SELECT b.PHONE AS PHONE,
b.PAYOFFUID,
IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN,
NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE
FROM EXCLUDE_CUST_INFO_FROM_APP b
left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE c on b.PAYOFFUID = c.PAYOFFUID
WHERE b.PHONE IN
(select PHONE from EXCLUDE_CUST_INFO_FROM_APP where PHONE is not null group by PHONE having count(*) = 1))
,LKP_PHONE_LOAN_MATCHING_CUST_INFO_AND_APP AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_MATCHING_CUST_INFO_AND_APP EXPLANATION
  Bring the data together from Customer info and Application togehter in a union. All 1:1s will have NULLs for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE while all 1:manys will have at least 1 value populated for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE.
************************************************************************************************************************/
( SELECT A.PHONE, A.PAYOFFUID, A.IS_LOAN, A.FIRST_POSSIBLE_CONTACT_DATE, A.LAST_POSSIBLE_CONTACT_DATE
FROM FULL_LKP_PHONE_LOAN_MATCHING_CUST_INFO A UNION SELECT B.PHONE, B.PAYOFFUID, B.IS_LOAN, B.FIRST_POSSIBLE_CONTACT_DATE, B.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_PHONE_LOAN_1_TO_1_MATCHING_APP B)
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_LEAD_MASTER_PII_UNIQUE BASE -- -- -- --
,EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER AS
/***********************************************************************************************************************
 EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER EXPLANATION
  This CTE excludes any phones that were identified from VW_CUSTOMER_INFO and VW_APPLICATION_PII to ensure there will be
  no repeats evaluated.
************************************************************************************************************************/
( SELECT IFF(LEN(regexp_replace(b.PHONE, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),1) = 1, RIGHT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),10),
regexp_replace(b.PHONE, '[^[:digit:]]', '')) AS PHONE,
b.PAYOFF_UID AS PAYOFFUID,
-- SSN is also taken from this view as another mechanism to match phones with individuals
b.SSN,
b.CREATED_AT_PST
FROM BUSINESS_INTELLIGENCE.PII.VW_LEAD_MASTER_PII_UNIQUE b
left join LKP_PHONE_LOAN_MATCHING_CUST_INFO_AND_APP a on a.PHONE = IFF(LEN(regexp_replace(b.PHONE, '[^[:digit:]]', '')) = 11
AND LEFT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),1) = 1,
RIGHT(regexp_replace(b.PHONE, '[^[:digit:]]', ''),10),
regexp_replace(b.PHONE, '[^[:digit:]]', ''))
where a.PHONE is null)
,MOST_USED_PHONE AS
/***********************************************************************************************************************
 MOST_USED_PHONE EXPLANATION
  This CTE takes phones and SSNs to create a matching criteria that fills in phones by SSN when there is a NULL phone value
  for a row of data that has the sam SSN utilized here.
************************************************************************************************************************/
( SELECT TEMP.* FROM
(SELECT SSN, PHONE, COUNT(*) AS TIMES_USED
FROM EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER
WHERE PHONE IS NOT NULL AND SSN IS NOT NULL
GROUP BY SSN, PHONE) TEMP
QUALIFY DENSE_RANK() OVER (PARTITION BY SSN ORDER BY TIMES_USED DESC, PHONE) = 1)
,LKP_PHONE_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_PHONE_LEAD_MASTER EXPLANATION
  This CTE fills in potentially missing phones by left joining MOST_USED_PHONE onto EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER
  by SSN, to fill in areas where there might have been missing phones from SSNs. Shoutout to Melissa for coming up with
  this methodology!
************************************************************************************************************************/
(SELECT COALESCE(A.PHONE,B.PHONE) AS PHONE,
                                  A.PAYOFFUID,
                                  A.SSN,
                                  a.CREATED_AT_PST
FROM EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER A
LEFT JOIN MOST_USED_PHONE B ON A.SSN = B.SSN)
,LKP_PHONE_LOAN_1_TO_1_MATCHING_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_PHONE_LEAD_MASTER CTE to get the loans that have a 1:1 relationship with
  phones, meaning that each phone is associated with one PayoffUID within the lead data.
************************************************************************************************************************/
(SELECT b.PHONE,
b.PAYOFFUID,
IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN
FROM LKP_PHONE_LEAD_MASTER b
left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE c on b.PAYOFFUID = c.PAYOFFUID
WHERE b.PHONE IN
(select PHONE from LKP_PHONE_LEAD_MASTER where PHONE is not null group by PHONE having count(*) = 1))
,LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_PHONE_LEAD_MASTER CTE to get the loans that do NOT have a 1:1 relationship with
  phones, meaning that each phone is associated with multiple PayoffUIDs. It matches these loans to loan tape, to see if they
  are loans. Their created date for the leads will serve as the basis for creating the boundaries in the future.
************************************************************************************************************************/
(SELECT a.PAYOFFUID,
       a.PHONE,
       a.SSN,
       IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN,
       A.CREATED_AT_PST AS CREATEDDATE
from LKP_PHONE_LEAD_MASTER a
LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE C ON A.PAYOFFUID = C.PAYOFFUID
where a.PHONE in
(select PHONE from LKP_PHONE_LEAD_MASTER where phone is not null group by PHONE having count(*) > 1))
,LATEST_LEAD_CREATED_PER_DAY_BY_PHONE AS
/***********************************************************************************************************************
 LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER CTE and gets the latest PayoffUID that was
  created each day for an phone. This is done because one phone can create multiple PayoffUIDs per day.
************************************************************************************************************************/
(SELECT
    A.PHONE,
    A.PAYOFFUID,
    A.IS_LOAN,
    A.CREATEDDATE
    FROM LKP_PHONE_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER A
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.PHONE, DATE(A.CREATEDDATE) ORDER BY A.CREATEDDATE DESC) = 1)
,LEAD_MASTER_CREATED_DATES AS
/***********************************************************************************************************************
 LEAD_MASTER_CREATED_DATES EXPLANATION
  This CTE is derived from the LATEST_LEAD_CREATED_PER_DAY_BY_PHONE CTE and creates the bounds for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE using the date the PII data for the lead was created. It uses IFF logic to create the
  boundaries.
************************************************************************************************************************/
(SELECT
    A.PHONE,
    A.PAYOFFUID,
    A.IS_LOAN,
    -- If there is another created date that is before this one, then mark the created date as the FIRST_POSSIBLE_CONTACT_DATE
    to_date(IFF(
        LAG(A.CREATEDDATE) OVER (PARTITION BY A.PHONE ORDER BY A.CREATEDDATE ASC) IS NOT NULL, A.CREATEDDATE, NULL
        )) AS FIRST_POSSIBLE_CONTACT_DATE,
    -- If there is another created date after this one, then fill take that date minus 1 day to make LAST_POSSIBLE_CONTACT_DATE
    to_date(DATEADD('day',-1,(LAG(CREATEDDATE) OVER (PARTITION BY A.PHONE ORDER BY CREATEDDATE DESC)))) AS LAST_POSSIBLE_CONTACT_DATE
    FROM LATEST_LEAD_CREATED_PER_DAY_BY_PHONE A)
,LEAD_MASTER_UNION AS
/***********************************************************************************************************************
 LEAD_MASTER_UNION EXPLANATION
  This CTE is derived from a union between the LKP_PHONE_LOAN_1_TO_1_MATCHING_LEAD_MASTER CTE and the LEAD_MASTER_CREATED_DATES
  CTEs to get the full data we can utilize from that source.
************************************************************************************************************************/
( SELECT PHONE, PAYOFFUID, IS_LOAN, FIRST_POSSIBLE_CONTACT_DATE, LAST_POSSIBLE_CONTACT_DATE FROM
(select b.PHONE, b.PAYOFFUID, b.IS_LOAN, NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE from LKP_PHONE_LOAN_1_TO_1_MATCHING_LEAD_MASTER b
union
select c.PHONE, c.PAYOFFUID, c.IS_LOAN, c.FIRST_POSSIBLE_CONTACT_DATE,
c.LAST_POSSIBLE_CONTACT_DATE from LEAD_MASTER_CREATED_DATES c)
--QUALIFY ROW_NUMBER() OVER (PARTITION BY PHONE, FIRST_POSSIBLE_CONTACT_DATE, LAST_POSSIBLE_CONTACT_DATE ORDER BY CREATEDDATE DESC) = 1
)
-- FINAL_UNION QUERY
/***********************************************************************************************************************
 FINAL_UNION EXPLANATION
  This is the final query that unions the  LKP_PHONE_LOAN_MATCHING_CUST_INFO_AND_APP CTE and LEAD_MASTER_UNION CTE to get
  the full data source that can be matched to on PHONE, FIRST_POSSIBLE_CONTACT_DATE, and LAST_POSSIBLE_CONTACT_DATE to obtain
  the loan/app/lead information for an interaction.
************************************************************************************************************************/
(SELECT a.PHONE, a.PAYOFFUID, a.IS_LOAN, a.FIRST_POSSIBLE_CONTACT_DATE, a.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_PHONE_LOAN_MATCHING_CUST_INFO_AND_APP a union
select b.PHONE, b.PAYOFFUID, b.IS_LOAN, b.FIRST_POSSIBLE_CONTACT_DATE, b.LAST_POSSIBLE_CONTACT_DATE
from LEAD_MASTER_UNION b);