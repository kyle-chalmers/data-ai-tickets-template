-- Original DDL for VW_DSH_MONTHLY_ROLL_RATE_MONITORING View (Original Version WITHOUT SIMM fields)
-- Retrieved: 2025-08-22
-- NOTE: This is the ORIGINAL state before DI-974 modifications

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING(
	PAYOFFUID,
	DPD,
	DPDCURRENT,
	DATECURRENT,
	DATEPREVIOUS,
	STATUSCURRENT,
	STATUSPREVIOUS,
	LOANSTATUSCURRENT,
	LOANSTATUSPREVIOUS,
	ROLL,
	LOANINTENT,
	ASOFDATE,
	PORTFOLIOID,
	PORTFOLIONAME,
	ORIGINATIONDATE,
	REGULARPAYMENTAMOUNT,
	LASTPAYMENTDATE,
	LASTPAYMENTAMOUNT,
	ACCRUEDINTEREST,
	BEGINNINGBALANCE,
	LOANAMOUNT,
	INTERESTPAYMENTAMOUNT,
	PRINCIPALPAYMENTAMOUNT,
	TOTALPAYMENTCOLLECTED,
	REMAININGPRINCIPAL,
	SERVICINGFEEAMOUNT,
	REMITTANCEAMOUNT,
	INTERESTPAIDTODATE,
	INTERESTPAIDTODATE_CU_CURRENT,
	PRINCIPALPAIDTODATE,
	PRINCIPALPAIDTODATE_CU_CURRENT,
	TERMSREMAINING,
	TOTALPRINCIPALWAIVED,
	NEXTPAYMENTDUEDATE,
	NEXTPRINCIPALAMOUNTDUE,
	NEXTINTERESTAMOUNTDUE,
	SERVICERFEERATE,
	STATUS,
	DAYSPASTDUE_LOANTAPE,
	PASTDUEINTEREST,
	TOTALNSFFEES,
	DEFERREDAMOUNT,
	DEFERREDPAYMENTDUEDATE,
	LOANMOD,
	LOANMODREASON,
	LOANMODINTERESTRATE,
	LOANMODTERMEXTENSION,
	LOANMODFORBEARANCE,
	LOANMODNEWMATURITY,
	LOANMODEFFECTIVEDATE,
	INTERNALSTATUS,
	CPVERSION_LOANTAPE,
	LOANTIER,
	LOAN_INTENT_LOANTAPE,
	BANKRUPTCYFLAG,
	TERM,
	ANNUALINCOME,
	BUREAUFICOSCORE,
	NDI,
	DTI,
	LAST_TOUCH_UTM_CHANNEL_GROUPING
) AS
SELECT
	A.PAYOFFUID,
	A.DPD,
	A.DPDCURRENT,
	A.DATECURRENT,
	A.DATEPREVIOUS,
	A.STATUSCURRENT,
	A.STATUSPREVIOUS,
	A.LOANSTATUSCURRENT,
	A.LOANSTATUSPREVIOUS,
	A.ROLL,
	A.LOANINTENT,
	B.ASOFDATE,
	B.PORTFOLIOID,
	B.PORTFOLIONAME,
	B.ORIGINATIONDATE,
	B.REGULARPAYMENTAMOUNT,
	B.LASTPAYMENTDATE,
	B.LASTPAYMENTAMOUNT,
	B.ACCRUEDINTEREST,
	B.BEGINNINGBALANCE,
	B.LOANAMOUNT,
	B.INTERESTPAYMENTAMOUNT,
	B.PRINCIPALPAYMENTAMOUNT,
	B.TOTALPAYMENTCOLLECTED,
	-- Remaining principal is the amount "cured"
	B.REMAININGPRINCIPAL,
	B.SERVICINGFEEAMOUNT,
	B.REMITTANCEAMOUNT,
	B.INTERESTPAIDTODATE,
	B.INTERESTPAIDTODATE_CU_CURRENT,
	B.PRINCIPALPAIDTODATE,
	B.PRINCIPALPAIDTODATE_CU_CURRENT,
	B.TERMSREMAINING,
	B.TOTALPRINCIPALWAIVED,
	B.NEXTPAYMENTDUEDATE,
	B.NEXTPRINCIPALAMOUNTDUE,
	B.NEXTINTERESTAMOUNTDUE,
	B.SERVICERFEERATE,
	B.STATUS,
	B.DAYSPASTDUE AS DAYSPASTDUE_LOANTAPE,
	B.PASTDUEINTEREST,
	B.TOTALNSFFEES,
	B.DEFERREDAMOUNT,
	B.DEFERREDPAYMENTDUEDATE,
	B.LOANMOD,
	B.LOANMODREASON,
	B.LOANMODINTERESTRATE,
	B.LOANMODTERMEXTENSION,
	B.LOANMODFORBEARANCE,
	B.LOANMODNEWMATURITY,
	B.LOANMODEFFECTIVEDATE,
	B.INTERNALSTATUS,
	-- INTERNAL FILTER
	B.CPVERSION AS CPVERSION_LOANTAPE,
    -- Because Theorem has a separate underwriting model, TH loans sometimes have null loan tier value (per Cale Williams)
	coalesce(B.LOANTIER, 'TH') as LOANTIER,
	B.LOAN_INTENT AS LOAN_INTENT_LOANTAPE,
	B.BANKRUPTCYFLAG,
	B.TERM,
	B.ANNUALINCOME,
	B.BUREAUFICOSCORE,
	B.NDI,
	B.DTI,
	C.LAST_TOUCH_UTM_CHANNEL_GROUPING
	---
FROM
	BUSINESS_INTELLIGENCE.CRON_STORE.RPT_TRANSITION_MATRIX_MONTHLY A
/***********************************************************************************************************************
Create Date:        2023-05-17
Author:             Kyle Chalmers
Description:        Use tableau_user to modify this view. This view loads all the necessary fields from
                    BUSINESS_INTELLIGENCE.CRON_STORE.RPT_TRANSITION_MATRIX_MONTHLY (BI-681) and
					BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
					to create the data source from which we can attribute (not with 100% accuracy) balances cured for delinquent
					accounts to agents and by channel and portfolio name. PLEASE NOTE THAT THE RPT_TRANSITION_MATRIX_MONTHLY table
					drops and refreshes every morning between 7am to ~8:30-9:00am, so this view might have no rows during that time,
					and for that reason the refresh of the dashboard itself is later than that. The data is transformed within the dashboard
					to display the desired metrics. Initial logic to this query was provided by Cale Williams.
Used by:            Balances Cured Tableau Dashboard:
                        <https://10ay.online.tableau.com/#/site/happymoney/workbooks/1173045?:origin=card_share_link>
                    Monthly Roll Rate Monitoring Dashboard:
                        <https://10ay.online.tableau.com/#/site/happymoney/workbooks/798563?:origin=card_share_link>
************************************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
2023-05-17          Kyle Chalmers       Created the view for monthly roll rate monitoring
2023-07-12          Kevin Liu           Added to LOANTIER logic to account for nulls ('TH')

***********************************************************************************************************************/
	-- Joined to loan tape to obtain the remaining principal balance
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY B
ON
	-- matching the interaction to the date in which it occurred
	-- the date is last day to make sure that the dates match since earlier dates in loan tape in 2020
	-- sometimes happen before the EOM
	LAST_DAY(DATE(A.DATECURRENT)) = LAST_DAY(DATE(B.ASOFDATE))
	AND A.PAYOFFUID = B.PAYOFFUID
LEFT JOIN DATA_STORE.MVW_APPL_STATUS_TRANSITION C
ON
	A.PAYOFFUID = C.PAYOFFUID
WHERE
	-- criteria recommended by Cale, where the distance between a current and previous
	-- date within this table should only be a month, and nothing more to keep the roll
	-- time period consistent for all loans
    -- USED ROUND BECAUSE AT TIMES THERE ARE MONTHS DIFFERENCE THAT IS +/- 0.1
	ROUND(MONTHS_BETWEEN(LAST_DAY(DATE(A.DATECURRENT)), LAST_DAY(DATE(A.DATEPREVIOUS))),0) = 1;
	-- putting in this particular criteria since before 2021-12-31 there are months between that are greater than 1
	--AND DATE(B.ASOFDATE) >= DATE('2021-12-31')