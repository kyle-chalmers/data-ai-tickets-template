create or replace dynamic table DT_LKP_EMAIL_TO_PAYOFFUID_MATCH(
	EMAIL,
	PAYOFFUID,
	IS_LOAN,
	FIRST_POSSIBLE_CONTACT_DATE,
	LAST_POSSIBLE_CONTACT_DATE
) target_lag = '3 days' refresh_mode = AUTO initialize = ON_CREATE warehouse = BUSINESS_INTELLIGENCE
 as
/*Create Date: 2024-03-08
Author: Kyle Chalmers
Description: Created as a result of this ticket: https://happymoneyinc.atlassian.net/browse/DI-113. The purpose of this table is designing the matching table for PayoffUIDs and emails. Please note all EMAIL fields are capitalized, and when joining to other emails, please capitalize those as well. There are 3 rules for this table:
An email has a 1:1 relationship with a PayoffUID, meaning that the email only is seen once for that single PayoffUID.
An email has a 1:Many relationship with PayoffUIDs, meaning that the same email is associated with multiple PayoffUIDs.
Data for PayoffUIDs associated with loans will take precedence over data for PayoffUIDs associated with leads.
For #2 in the list, the two fields FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE are created to utilize when joining to interaction data, so interactions happen between those bounds. If there is a NULL value for that column, it means there is no boundary. If there are multiple loans associated with the same email, the latest created PayoffUID will have a NULL for LAST_POSSIBLE_CONTACT_DATE, and the earliest created PayoffUID will have a NULL value for FIRST_POSSIBLE_CONTACT_DATE.
For #3 in the list, all emails that are associated with loans, will be associated with those PayoffUIDs, before any others. So if those emails are found to be associated with PayoffUIDs that are loans, then they will not be matched to any PayoffUIDs that are for leads that never turned into loans.
The query is comprised of 3 main data sources from BUSINESS_INTELLIGENCE.PII :

VW_CUSTOMER_INFO
VW_APPLICATION_PII
VW_LEAD_MASTER_PII_UNIQUE

Please note that this data still should be secondary to any list data generated on particular days, as that data will be able to match to Genesys using the inin-outbound-id, utilizing the export from Genesys. However, currently, there are no lists generated that utilize email, as they only use phone number.
TODO: INVESTIGATE THE POSSIBILITY OF UTILIZING VW_APPLICATION_PII WITH 1:MANY EMAIL TO PAYOFFUIDS RELATIONSHIPS*/
-- -- -- -- -- -- -- -- -- FINAL EMAIL TABLE -- -- -- -- -- -- -- -- --
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO BASE -- -- -- --
-- Please note VW_CUSTOMER_INFO only contains loans within the view, hence the TRUE AS IS_LOAN field.
WITH LKP_EMAIL_LOAN_1_TO_1_MATCHING_CUST_INFO AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_1_TO_1_MATCHING_CUST_INFO EXPLANATION
  This CTE is derived from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO to get the loans that have a 1:1 relationship with.
  emails, meaning that each email is associated with one PayoffUID.
************************************************************************************************************************/
(SELECT --KEY: ensure emails are all caps
UPPER(a.EMAIL) as EMAIL,
a.PAYOFFUID,
TRUE AS IS_LOAN,
NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a
-- KEY: Filter criteria to ensure we are only getting emails that have 1:1 relationship with PayoffUIDs
where UPPER(a.EMAIL) in
(select UPPER(EMAIL) from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO WHERE EMAIL IS NOT NULL group by UPPER(EMAIL) having count(*) = 1))
,LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO EXPLANATION
  This CTE is derived from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO to get the loans that do NOT have a 1:1 relationship with.
  emails, meaning that each email is associated with multiple PayoffUIDs. It matches these loans to loan tape, to get their
  closed date, which will serve as a boundary in the following queries.
************************************************************************************************************************/
(SELECT --KEY: ensure emails are all caps
UPPER(a.EMAIL) as EMAIL,
a.PAYOFFUID,
TRUE AS IS_LOAN,
T.LOANCLOSEDDATE AS END_DATE
from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO a
LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE T ON A.PAYOFFUID = T.PAYOFFUID
-- KEY: Filter criteria to ensure we are only getting emails that have 1:1 relationship with PayoffUIDs
where UPPER(a.EMAIL) in
(select UPPER(EMAIL) from BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO WHERE EMAIL IS NOT NULL group by UPPER(EMAIL) having count(*) > 1))
,CUST_INFO_CONTACT_DATES_FIRST_STAGE AS
/***********************************************************************************************************************
 CUST_INFO_CONTACT_DATES_FIRST_STAGE EXPLANATION
  For the emails associated with multiple PayoffUIDs from LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO, it uses the the
  Loan Close Date with LAG functions and logic to derive the first stage of date boundaries for interactions associated
  with the email and loans.
************************************************************************************************************************/
(SELECT
    A.EMAIL,
    A.PAYOFFUID,
    A.IS_LOAN,
    A.END_DATE,
    -- If there is another loan after this one, obtain its end date
    LAG(A.END_DATE) OVER (PARTITION BY A.EMAIL ORDER BY A.END_DATE DESC) AS NEXT_END_DATE,
    -- If there was a loan before this one, take its end date + 1 to make it the first possible contact date
    DATEADD('day',1,(LAG(A.END_DATE) OVER (PARTITION BY A.EMAIL ORDER BY A.END_DATE))) AS FIRST_POSSIBLE_CONTACT_DATE,
    -- If there is no next end date, and the first possible contact date is not null, then this is the last loan for this
    -- email, so there should be no last contact date. Otherwise, it should have a last possible contact date.
    IFF(NEXT_END_DATE IS NULL AND FIRST_POSSIBLE_CONTACT_DATE IS NOT NULL, NULL, A.END_DATE) AS LAST_POSSIBLE_CONTACT_DATE
    FROM LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_CUST_INFO A)
,CUST_INFO_CONTACT_DATES_FINAL_STAGE AS
/***********************************************************************************************************************
 CUST_INFO_CONTACT_DATES_FINAL_STAGE EXPLANATION
  This builds off of CUST_INFO_CONTACT_DATES_FIRST_STAGE to ensure all data is correctly presented to be matched to the
  interaction data from Genesys.
************************************************************************************************************************/
(SELECT A.EMAIL,
PAYOFFUID,
IS_LOAN,
FIRST_POSSIBLE_CONTACT_DATE,
-- If there is a loan that comes after the current loan, then we need to ensure that this loan has its close date as the
-- last possible contact date.
IFF((LAG(A.FIRST_POSSIBLE_CONTACT_DATE) OVER (PARTITION BY A.EMAIL ORDER BY A.END_DATE DESC)) IS NOT NULL
           AND LAST_POSSIBLE_CONTACT_DATE IS NULL,
           END_DATE,LAST_POSSIBLE_CONTACT_DATE) AS LAST_POSSIBLE_CONTACT_DATE
    FROM CUST_INFO_CONTACT_DATES_FIRST_STAGE A
-- There should not be any loans where first possible contact date, and last possible contact date, equal each other
-- from this section.
WHERE IFNULL(FIRST_POSSIBLE_CONTACT_DATE,'1999-02-01') <> IFNULL(LAST_POSSIBLE_CONTACT_DATE,'1999-02-01'))
,FULL_LKP_EMAIL_LOAN_MATCHING_CUST_INFO AS (
/***********************************************************************************************************************
 FULL_LKP_EMAIL_LOAN_MATCHING_CUST_INFO EXPLANATION
  Bring the data together in a union. All 1:1s will have NULLs for FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE
  while all 1:manys will have at least 1 value populated for FIRST_POSSIBLE_CONTACT_DATE and LAST_POSSIBLE_CONTACT_DATE.
************************************************************************************************************************/
( SELECT A.EMAIL, A.PAYOFFUID, A.IS_LOAN, A.FIRST_POSSIBLE_CONTACT_DATE, A.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_EMAIL_LOAN_1_TO_1_MATCHING_CUST_INFO A
UNION SELECT B.EMAIL, B.PAYOFFUID, B.IS_LOAN, B.FIRST_POSSIBLE_CONTACT_DATE, B.LAST_POSSIBLE_CONTACT_DATE
FROM CUST_INFO_CONTACT_DATES_FINAL_STAGE B))
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_APPLICATION_PII BASE -- -- -- --
-- Please note only 1:1 relationships are taken from VW_APPLICATION_PII to simplify the query
-- and the rest of the 1:many relationships are pulled from VW_LEAD_MASTER_PII_UNIQUE.
,EXCLUDE_CUST_INFO_FROM_APP AS
/***********************************************************************************************************************
 EXCLUDE_CUST_INFO_FROM_APP EXPLANATION
  This CTE excludes any emails that were identified from VW_CUSTOMER_INFO to ensure there will be no repeats evaluated.
************************************************************************************************************************/
(SELECT UPPER(B.EMAIL) as EMAIL,
b.PAYOFF_UID AS PAYOFFUID
from BUSINESS_INTELLIGENCE.PII.VW_APPLICATION_PII b
left join FULL_LKP_EMAIL_LOAN_MATCHING_CUST_INFO a on a.EMAIL = UPPER(b.EMAIL)
where a.EMAIL is null)
,LKP_EMAIL_LOAN_1_TO_1_MATCHING_APP AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_1_TO_1_MATCHING_APP EXPLANATION
  This CTE is derived from EXCLUDE_CUST_INFO_FROM_APP CTE to get the loans that have a 1:1 relationship with.
  emails, meaning that each email is associated with one PayoffUID, using PII from their application.
************************************************************************************************************************/
(SELECT b.EMAIL AS EMAIL,
b.PAYOFFUID,
IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN,
NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE
FROM EXCLUDE_CUST_INFO_FROM_APP b
left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE c on b.PAYOFFUID = c.PAYOFFUID
WHERE UPPER(b.EMAIL) IN
(select UPPER(EMAIL) from EXCLUDE_CUST_INFO_FROM_APP where EMAIL is not null group by UPPER(EMAIL) having count(*) = 1))
,LKP_EMAIL_LOAN_MATCHING_CUST_INFO_AND_APP AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_MATCHING_CUST_INFO_AND_APP EXPLANATION
  Bring the data together from Customer info and Application togehter in a union. All 1:1s will have NULLs for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE while all 1:manys will have at least 1 value populated for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE.
************************************************************************************************************************/
( SELECT A.EMAIL, A.PAYOFFUID, A.IS_LOAN, A.FIRST_POSSIBLE_CONTACT_DATE, A.LAST_POSSIBLE_CONTACT_DATE
FROM FULL_LKP_EMAIL_LOAN_MATCHING_CUST_INFO A UNION SELECT B.EMAIL, B.PAYOFFUID, B.IS_LOAN, B.FIRST_POSSIBLE_CONTACT_DATE, B.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_EMAIL_LOAN_1_TO_1_MATCHING_APP B)
-- -- -- -- BUSINESS_INTELLIGENCE.PII.VW_LEAD_MASTER_PII_UNIQUE BASE -- -- -- --
,EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER AS
/***********************************************************************************************************************
 EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER EXPLANATION
  This CTE excludes any emails that were identified from VW_CUSTOMER_INFO and VW_APPLICATION_PII to ensure there will be
  no repeats evaluated.
************************************************************************************************************************/
( SELECT UPPER(b.EMAIL) AS EMAIL,
b.PAYOFF_UID AS PAYOFFUID,
-- SSN is also taken from this view as another mechanism to match emails with individuals
b.SSN,
b.CREATED_AT_PST
FROM BUSINESS_INTELLIGENCE.PII.VW_LEAD_MASTER_PII_UNIQUE b
left join LKP_EMAIL_LOAN_MATCHING_CUST_INFO_AND_APP a on a.EMAIL = UPPER(b.EMAIL)
where a.EMAIL is null)
,MOST_USED_EMAIL AS
/***********************************************************************************************************************
 MOST_USED_EMAIL EXPLANATION
  This CTE takes emails and SSNs to create a matching criteria that fills in emails by SSN when there is a NULL email value
  for a row of data that has the sam SSN utilized here.
************************************************************************************************************************/
( SELECT TEMP.* FROM
(SELECT SSN, EMAIL, COUNT(*) AS TIMES_USED
FROM EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER
WHERE EMAIL IS NOT NULL AND SSN IS NOT NULL
GROUP BY SSN, EMAIL) TEMP
QUALIFY DENSE_RANK() OVER (PARTITION BY SSN ORDER BY TIMES_USED DESC, EMAIL) = 1)
,LKP_EMAIL_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_EMAIL_LEAD_MASTER EXPLANATION
  This CTE fills in potentially missing emails by left joining MOST_USED_EMAIL onto EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER
  by SSN, to fill in areas where there might have been missing emails from SSNs. Shoutout to Melissa for coming up with
  this methodology!
************************************************************************************************************************/
(SELECT COALESCE(A.EMAIL,B.EMAIL) AS EMAIL,
                                  A.PAYOFFUID,
                                  A.SSN,
                                  a.CREATED_AT_PST
FROM EXCLUDE_CUST_INFO_AND_APP_FROM_LEAD_MASTER A
LEFT JOIN MOST_USED_EMAIL B ON A.SSN = B.SSN)
,LKP_EMAIL_LOAN_1_TO_1_MATCHING_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_EMAIL_LEAD_MASTER CTE to get the loans that have a 1:1 relationship with
  emails, meaning that each email is associated with one PayoffUID within the lead data.
************************************************************************************************************************/
(SELECT b.EMAIL,
b.PAYOFFUID,
IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN
FROM LKP_EMAIL_LEAD_MASTER b
left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE c on b.PAYOFFUID = c.PAYOFFUID
WHERE b.EMAIL IN
(select EMAIL from LKP_EMAIL_LEAD_MASTER where EMAIL is not null group by EMAIL having count(*) = 1))
,LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_EMAIL_LEAD_MASTER CTE to get the loans that do NOT have a 1:1 relationship with
  emails, meaning that each email is associated with multiple PayoffUIDs. It matches these loans to loan tape, to see if they
  are loans. Their created date for the leads will serve as the basis for creating the boundaries in the future.
************************************************************************************************************************/
(SELECT a.PAYOFFUID,
       a.EMAIL,
       a.SSN,
       IFF(C.PAYOFFUID IS NULL, FALSE, TRUE) AS IS_LOAN,
       A.CREATED_AT_PST AS CREATEDDATE
from LKP_EMAIL_LEAD_MASTER a
LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE C ON A.PAYOFFUID = C.PAYOFFUID
where a.EMAIL in
(select EMAIL from LKP_EMAIL_LEAD_MASTER where email is not null group by EMAIL having count(*) > 1))
,LATEST_LEAD_CREATED_PER_DAY_BY_EMAIL AS
/***********************************************************************************************************************
 LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER EXPLANATION
  This CTE is derived from the LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER CTE and gets the latest PayoffUID that was
  created each day for an email. This is done because one email can create multiple PayoffUIDs per day.
************************************************************************************************************************/
(SELECT
    A.EMAIL,
    A.PAYOFFUID,
    A.IS_LOAN,
    A.CREATEDDATE
    FROM LKP_EMAIL_LOAN_NOT_1_TO_1_MATCHING_LEAD_MASTER A
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.EMAIL, DATE(A.CREATEDDATE) ORDER BY A.CREATEDDATE DESC) = 1)
,LEAD_MASTER_CREATED_DATES AS
/***********************************************************************************************************************
 LEAD_MASTER_CREATED_DATES EXPLANATION
  This CTE is derived from the LATEST_LEAD_CREATED_PER_DAY_BY_EMAIL CTE and creates the bounds for FIRST_POSSIBLE_CONTACT_DATE
  and LAST_POSSIBLE_CONTACT_DATE using the date the PII data for the lead was created. It uses IFF logic to create the
  boundaries.
************************************************************************************************************************/
(SELECT
    A.EMAIL,
    A.PAYOFFUID,
    A.IS_LOAN,
    -- If there is another created date that is before this one, then mark the created date as the FIRST_POSSIBLE_CONTACT_DATE
    to_date(IFF(
        LAG(A.CREATEDDATE) OVER (PARTITION BY A.EMAIL ORDER BY A.CREATEDDATE ASC) IS NOT NULL, A.CREATEDDATE, NULL
        )) AS FIRST_POSSIBLE_CONTACT_DATE,
    -- If there is another created date after this one, then fill take that date minus 1 day to make LAST_POSSIBLE_CONTACT_DATE
    to_date(DATEADD('day',-1,(LAG(CREATEDDATE) OVER (PARTITION BY A.EMAIL ORDER BY CREATEDDATE DESC)))) AS LAST_POSSIBLE_CONTACT_DATE
    FROM LATEST_LEAD_CREATED_PER_DAY_BY_EMAIL A)
,LEAD_MASTER_UNION AS
/***********************************************************************************************************************
 LEAD_MASTER_UNION EXPLANATION
  This CTE is derived from a union between the LKP_EMAIL_LOAN_1_TO_1_MATCHING_LEAD_MASTER CTE and the LEAD_MASTER_CREATED_DATES
  CTEs to get the full data we can utilize from that source.
************************************************************************************************************************/
( SELECT EMAIL, PAYOFFUID, IS_LOAN, FIRST_POSSIBLE_CONTACT_DATE, LAST_POSSIBLE_CONTACT_DATE FROM
(select b.EMAIL, b.PAYOFFUID, b.IS_LOAN, NULL AS FIRST_POSSIBLE_CONTACT_DATE,
NULL AS LAST_POSSIBLE_CONTACT_DATE from LKP_EMAIL_LOAN_1_TO_1_MATCHING_LEAD_MASTER b
union
select c.EMAIL, c.PAYOFFUID, c.IS_LOAN, c.FIRST_POSSIBLE_CONTACT_DATE,
c.LAST_POSSIBLE_CONTACT_DATE from LEAD_MASTER_CREATED_DATES c)
--QUALIFY ROW_NUMBER() OVER (PARTITION BY EMAIL, FIRST_POSSIBLE_CONTACT_DATE, LAST_POSSIBLE_CONTACT_DATE ORDER BY CREATEDDATE DESC) = 1
)
-- FINAL_UNION QUERY
/***********************************************************************************************************************
 FINAL_UNION EXPLANATION
  This is the final query that unions the  LKP_EMAIL_LOAN_MATCHING_CUST_INFO_AND_APP CTE and LEAD_MASTER_UNION CTE to get
  the full data source that can be matched to on EMAIL, FIRST_POSSIBLE_CONTACT_DATE, and LAST_POSSIBLE_CONTACT_DATE to obtain
  the loan/app/lead information for an interaction.
************************************************************************************************************************/
(SELECT a.EMAIL, a.PAYOFFUID, a.IS_LOAN, a.FIRST_POSSIBLE_CONTACT_DATE, a.LAST_POSSIBLE_CONTACT_DATE
FROM LKP_EMAIL_LOAN_MATCHING_CUST_INFO_AND_APP a union
select b.EMAIL, b.PAYOFFUID, b.IS_LOAN, b.FIRST_POSSIBLE_CONTACT_DATE, b.LAST_POSSIBLE_CONTACT_DATE
from LEAD_MASTER_UNION b);