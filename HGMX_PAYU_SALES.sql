USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_PAYU_SALES]    Script Date: 12/2/2020 10:26:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- HGMX PayU Sales (Cash SPS)
-- By: Alan Jackson
-- Created on: 9/1/2020

ALTER   PROCEDURE [dbo].[HGMX_PAYU_SALES] @vDate VARCHAR(25) AS

--EXEC HGMX_DROPS

--DECLARE @vDate VARCHAR(50)
--SET @vDate = '20200802'

DECLARE @vDate_Datetime DATETIME
SET @vDate_Datetime = @vDate

DECLARE @vDate_MMddyyyy VARCHAR(20)
SET @vDate_MMddyyyy = FORMAT(@vDate_Datetime, 'MMddyyyy')

-- Summarize revenue from PAYU txns in GT Report

SELECT
	COMPANY_CALC
	, TYPE_CALC
	, BUSINESS_LINE_CALC
	, Currency
	, SUM(REVENUE_AMOUNT_USD_CALC) AS REVENUE_AMOUNT_USD_CALC
	, @vDate_MMddyyyy AS zPAYU_Date
INTO
	HGMX_PAYU_GT_Summ
FROM
	HGMX_GT
WHERE
	Settledby_Calc = 'PayU'
GROUP BY
	COMPANY_CALC
	, TYPE_CALC
	, BUSINESS_LINE_CALC
	, Currency

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PAYU_GT_Summ'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PAYU_GT_Summ'
	, @CHECKBOOKID = 'PAYU'
	, @BATCHID = @vDate_MMddyyyy
	, @TRANTYPE = 5
	, @TRANDATE = @vDate_MMddyyyy

UPDATE A SET A.ACCOUNT = ISNULL(B.Account_Num, 'XXX-XXXXX-XXX')
FROM HGMX_PAYU_GT_Summ A
LEFT JOIN GTStage_Matt.dbo.hgmx_accounts_matrix_v2 B	ON A.TYPE_CALC = B.TYPE_CALC AND A.BUSINESS_LINE_CALC = B.BUSINESS_LINE_CALC;

UPDATE HGMX_PAYU_GT_Summ SET REFERENCE = zPAYU_Date + ' CASH PAYU'
UPDATE HGMX_PAYU_GT_Summ SET DEBIT = (CASE WHEN REVENUE_AMOUNT_USD_CALC > 0 THEN 0 ELSE REVENUE_AMOUNT_USD_CALC * -1 END)
UPDATE HGMX_PAYU_GT_Summ SET CREDIT = (CASE WHEN REVENUE_AMOUNT_USD_CALC < 0 THEN 0 ELSE REVENUE_AMOUNT_USD_CALC END )
UPDATE HGMX_PAYU_GT_Summ SET DISTREF = COMPANY_CALC + ' ' + TYPE_CALC + ' ' + BUSINESS_LINE_CALC + ' ' + Currency + ' - PAYU SALES'
UPDATE HGMX_PAYU_GT_Summ SET UNIQUEID = 'HGMXPU' + @vDate_MMddyyyy + @vDate_MMddyyyy

SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID INTO HGMX_PAYU_JE FROM HGMX_PAYU_GT_Summ

-- Summarize Tax collected from PAYU txns in GT report.

SELECT 
	COMPANY_CALC
	, Currency
	, TAX_TYPE_CALC
	, SUM(TAX_AMOUNT_USD_CALC) AS TAX_AMOUNT_USD_CALC
INTO HGMX_PAYU_GT_Tax_Summ
FROM HGMX_GT
WHERE Settledby_Calc = 'PAYU' AND TAX_AMOUNT_USD_CALC <> 0 
GROUP BY 
	COMPANY_CALC
	, Currency
	, TAX_TYPE_CALC

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PAYU_GT_Tax_Summ'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PAYU_GT_Tax_Summ'
				, @CHECKBOOKID = 'PAYU'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_PAYU_GT_Tax_Summ SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYU'
UPDATE HGMX_PAYU_GT_Tax_Summ SET ACCOUNT = (CASE
		 WHEN TAX_TYPE_CALC = 'VAT' THEN '061-24910-000'
		 WHEN TAX_TYPE_CALC = 'UST' THEN '061-21120-000'
	 		ELSE '061-24940-000' END)
UPDATE HGMX_PAYU_GT_Tax_Summ SET DEBIT = (CASE WHEN TAX_AMOUNT_USD_CALC > 0 THEN 0 ELSE TAX_AMOUNT_USD_CALC * -1 END) 
UPDATE HGMX_PAYU_GT_Tax_Summ SET CREDIT = (CASE WHEN TAX_AMOUNT_USD_CALC < 0 THEN 0 ELSE TAX_AMOUNT_USD_CALC END)
UPDATE HGMX_PAYU_GT_Tax_Summ SET DISTREF = COMPANY_CALC + ' PAYU ' + Currency + ' - ' + TAX_TYPE_CALC + ' PAYABLE'
UPDATE HGMX_PAYU_GT_Tax_Summ SET UNIQUEID = 'HGMXPU' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PAYU_JE', @InsertFromTableName = 'HGMX_PAYU_GT_Tax_Summ'

--- Start summarizing HGMX PAYU Merchant Report to get Suspense ----

SELECT * INTO HGMX_PAYU
FROM GTStage.dbo.GT_Processed_HGLATAM_PayU
WHERE CAST(Update_date AS DATE) = @vDate
AND Status = 'APPROVED'

ALTER TABLE HGMX_PAYU
 ADD zImport_Date VARCHAR(12)
 	, PAYU_Gross_Amt_CALC DECIMAL(15,2)
 --	, PAYU_Fee_Amt_CALC DECIMAL(15,2)
 	, PAYU_Activity_Date VARCHAR(15)
 	, PAYU_Property_CALC VARCHAR(20)
 	, PAYU_TxnID_CALC VARCHAR(50)
 --	, PAYU_Txn_Event_Type_CALC VARCHAR(150)
 --	, PAYU_Txn_Event_Code_CALC VARCHAR(30)
 --	, PAYU_Exclude_CALC VARCHAR(5)
 --	, PAYU_Fee_Amt_USD_Calc DECIMAL(15,2)
 	, PAYU_FX_RATE_INVRS DECIMAL(10,4) 

UPDATE PAYU
SET PAYU.PAYU_FX_RATE_INVRS = ISNULL(FX.InvrsRate_CALC, 1) 
FROM HGMX_PAYU PAYU
LEFT JOIN [GTStage].[dbo].[GT_PROCESSED_EXCHANGERATE] FX ON FX.BASECURRENCYCODE = PAYU.Transaction_currency
	AND CAST(PAYU.Creation_date AS DATE) = FX.DATECONVERSION

UPDATE HGMX_PAYU SET zImport_Date = @vDate
UPDATE HGMX_PAYU SET PAYU_Gross_Amt_CALC = CAST(Processing_value AS FLOAT)
--UPDATE HGMX_PAYU SET PAYU_Fee_Amt_CALC = (CASE WHEN Transaction_Debit_or_Credit = 'DR' THEN -1 * (CAST(Fee_Amount AS float) / 100.00) ELSE CAST(Fee_Amount AS float) / 100.00 END)
UPDATE HGMX_PAYU SET PAYU_Activity_Date = FORMAT(Creation_date, 'yyyyMMdd')
UPDATE HGMX_PAYU SET PAYU_Property_CALC = 'HGMX'
--UPDATE HGMX_PAYU SET PAYU_Fee_Amt_USD_Calc = ISNULL(Fee_Amount, 0) * PAYU_FX_RATE_INVRS
UPDATE HGMX_PAYU SET PAYU_TxnID_CALC = Id 


-- Start building PAYU Exception Report --

-- Summarize PAYU Txns in GT Report

SELECT * INTO HGMX_GT_PAYU_Suspense
FROM 
	(SELECT
		COMPANY_CALC
		, ISNULL(Unique_Trans_ID, '1') Unique_Trans_ID
		, Currency as GT_Currency
		, SUM(TRANS_AMOUNT_USD_CALC) GT_TRANS_AMT_USD_CALC
		, SUM(TRANS_AMOUNT_LOCAL_CALC) GT_TRANS_AMT_LOCAL_CALC
		, Date as GT_Date
	FROM HGMX_GT
	WHERE Settledby_Calc = 'PAYU'
	GROUP BY COMPANY_CALC, Unique_Trans_ID, Currency, Date) GT

	-- Summarize PAYU Txns in PAYU Merchant Report

SELECT
	PAYU_Property_CALC
	, PAYU_TxnID_CALC
	, Transaction_Currency as PAYU_Gross_Amt_Currency
	, SUM(PAYU_Gross_Amt_CALC) AS PAYU_Gross_Amt_CALC
	--, SUM(ISNULL(PAYU_Fee_Amt_CALC, 0) * PAYU_FX_RATE_INVRS) AS PAYU_Fee_Amt_USD_Calc
	--, Transaction_Event_Code
	, CAST(SUM(PAYU_Gross_Amt_CALC * PAYU_FX_RATE_INVRS) AS DECIMAL(15,2)) AS PAYU_Gross_Amt_USD_CALC
	, PAYU_FX_RATE_INVRS
	, CAST(PAYU_Activity_Date AS DATE) PAYU_Activity_Date
INTO HGMX_PAYU_Suspense
FROM HGMX_PAYU
GROUP BY
	PAYU_Property_CALC
	, PAYU_TxnID_CALC
	, Transaction_currency
--	, Transaction_Event_Code
	, PAYU_FX_RATE_INVRS
	, PAYU_Activity_Date

-- Full join between GT & PayU to get all matched and unmatched txns.
SELECT GT.*, PAYU.*
INTO HGMX_GT_PAYU_FullJoin
FROM HGMX_GT_PAYU_Suspense GT
FULL JOIN (SELECT * FROM HGMX_PAYU_Suspense) PAYU
	ON GT.Unique_Trans_ID = PAYU.PAYU_TxnID_CALC

ALTER TABLE HGMX_GT_PAYU_FullJoin
 ADD zChargeback VARCHAR(25)
	, zCurrency_All VARCHAR(55)
 	, zCBack_Amount DECIMAL(15,2)
 	, zTrans_Amt_Diff DECIMAL(15,2)
 	, zFX_Diff DECIMAL(10,2)
 	, zOther_Diff DECIMAL(15,2)
 	, zAll_Company VARCHAR(50)

UPDATE HGMX_GT_PAYU_FullJoin 
SET zChargeback = 'No' -- (CASE WHEN Transaction_Event_Code IN ('T1106','T1201','T1202','T1110','T1111','T1114') THEN 'Yes' ELSE 'No' END)

UPDATE HGMX_GT_PAYU_FullJoin 
SET zCBack_Amount = (CASE WHEN zChargeback = 'Yes' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END) 

UPDATE HGMX_GT_PAYU_FullJoin 
SET zTrans_Amt_Diff = (CASE WHEN zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PAYU_FullJoin 
SET zFX_Diff = (CASE WHEN GT_TRANS_AMT_LOCAL_CALC = PAYU_Gross_Amt_CALC AND zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PAYU_FullJoin SET zOther_Diff = zTrans_Amt_Diff - zFX_Diff

UPDATE HGMX_GT_PAYU_FullJoin 
SET zAll_Company = (CASE WHEN COMPANY_CALC IS NOT NULL THEN COMPANY_CALC ELSE PAYU_Property_CALC END)

UPDATE HGMX_GT_PAYU_FullJoin 
SET zCurrency_All = (CASE WHEN GT_Currency IS NULL THEN PAYU_Gross_Amt_Currency ELSE GT_Currency END)


-- Join PP and GT reports at the same level of summarization to identify exceptions.
SELECT GT.*, PAYU.*
INTO HGMX_GT_PAYU_FullOuterJoin
FROM HGMX_GT_PAYU_Suspense GT
FULL OUTER JOIN (SELECT * FROM HGMX_PAYU_Suspense) PAYU
	ON GT.Unique_Trans_ID = PAYU.PAYU_TxnID_CALC

ALTER TABLE HGMX_GT_PAYU_FullOuterJoin
 ADD zChargeback VARCHAR(25)
	, zCurrency_All VARCHAR(55)
 	, zCBack_Amount DECIMAL(15,2)
 	, zTrans_Amt_Diff DECIMAL(15,2)
 	, zFX_Diff DECIMAL(10,2)
 	, zOther_Diff DECIMAL(15,2)
 	, zAll_Company VARCHAR(50)

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zChargeback = 'No' -- (CASE WHEN Transaction_Event_Code IN ('T1106','T1201','T1202','T1110','T1111','T1114') THEN 'Yes' ELSE 'No' END)

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zCBack_Amount = (CASE WHEN zChargeback = 'Yes' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END) 

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zTrans_Amt_Diff = (CASE WHEN zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zFX_Diff = (CASE WHEN GT_TRANS_AMT_LOCAL_CALC = PAYU_Gross_Amt_CALC AND zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PAYU_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PAYU_FullOuterJoin SET zOther_Diff = zTrans_Amt_Diff - zFX_Diff

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zAll_Company = (CASE WHEN COMPANY_CALC IS NOT NULL THEN COMPANY_CALC ELSE PAYU_Property_CALC END)

UPDATE HGMX_GT_PAYU_FullOuterJoin 
SET zCurrency_All = (CASE WHEN GT_Currency IS NULL THEN PAYU_Gross_Amt_Currency ELSE GT_Currency END)

/* Summarized Exception Table
select count(unique_trans_id), sum(gt_trans_amt_usd_calc), sum(payu_gross_amt_usd_calc) 
from HGMX_GT_PAYU_FullOuterJoin
where Unique_Trans_ID is not null
union all
select count(unique_trans_id), sum(gt_trans_amt_usd_calc), sum(payu_gross_amt_usd_calc) 
from HGMX_GT_PAYU_FullOuterJoin
where Unique_Trans_ID is null
*/

	-- Summarize PAYU Suspense for JE
SELECT 
	zAll_Company
	, zCurrency_All
	, SUM(zOther_Diff) AS Suspense_Amount
	, SUM(zFX_Diff) AS FX_Amount
	, SUM(zCBack_Amount) AS CBack_Amount
	--, SUM(PAYU_Fee_Amt_USD_Calc) AS PAYU_Fee_Amt_USD_Calc
INTO HGMX_PAYU_Suspense_JE
FROM HGMX_GT_PAYU_FullOuterJoin
GROUP BY zAll_Company, zCurrency_All

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PAYU_Suspense_JE'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PAYU_Suspense_JE'
				, @CHECKBOOKID = 'PAYU'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy
UPDATE HGMX_PAYU_Suspense_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYU'
UPDATE HGMX_PAYU_Suspense_JE SET ACCOUNT = '061-11045-000'
UPDATE HGMX_PAYU_Suspense_JE SET DEBIT = (CASE WHEN Suspense_Amount > 0 THEN Suspense_Amount ELSE 0 END)
UPDATE HGMX_PAYU_Suspense_JE SET CREDIT = (CASE WHEN Suspense_Amount < 0 THEN Suspense_Amount * -1 ELSE 0 END)
UPDATE HGMX_PAYU_Suspense_JE SET DISTREF = zAll_Company + ' PAYU ' + zCurrency_All + ' SUSPENSE - PAYU SALES'
UPDATE HGMX_PAYU_Suspense_JE SET UNIQUEID = 'HGMXPU' + @vDate_MMddyyyy + @vDate_MMddyyyy

IF (SELECT SUM(DEBIT) + SUM(CREDIT) FROM HGMX_PAYU_Suspense_JE) > 0 
BEGIN 
	EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PAYU_JE', @InsertFromTableName = 'HGMX_PAYU_Suspense_JE'
END


/*
End PAYU Exception JE; Start CBacks JE

As of 9/2/20 there are no negative transaction amounts
in the PayU merchant report so there will be
no chargeback entries created as of now. 

Same goes for Fees - no column in Merchant report to denote fees...or taxes.

*/

-- Start Cash JE
SELECT 
	CHECKBOOKID AS zCBOOKID
	, SUM(CREDIT) AS SUM_CREDIT
	, SUM(DEBIT) AS SUM_DEBIT
INTO HGMX_PAYU_Cash_JE
FROM HGMX_PAYU_JE
WHERE LEFT(DISTREF, 4) = 'HGMX'
GROUP BY CHECKBOOKID

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PAYU_Cash_JE'
ALTER TABLE HGMX_PAYU_Cash_JE
 ADD PLUG_CALC DECIMAL(15,2)
 	, CURRENCY_CALC VARCHAR(50)

UPDATE HGMX_PAYU_Cash_JE SET PLUG_CALC = (SUM_CREDIT - SUM_DEBIT)
UPDATE HGMX_PAYU_Cash_JE SET CURRENCY_CALC = CHECKBOOKID  

EXEC spUpdateJE @TabletoUpdate = 'HGMX_PAYU_Cash_JE'
				, @CHECKBOOKID = 'PAYU'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_PAYU_Cash_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYU'
UPDATE HGMX_PAYU_Cash_JE SET ACCOUNT = '061-11001-000'
UPDATE HGMX_PAYU_Cash_JE SET DEBIT = (CASE WHEN PLUG_CALC > 0 THEN PLUG_CALC ELSE 0 END)
UPDATE HGMX_PAYU_Cash_JE SET CREDIT = (CASE WHEN PLUG_CALC < 0 THEN PLUG_CALC * -1 ELSE 0 END)
UPDATE HGMX_PAYU_Cash_JE SET DISTREF = 'HGMX CASH USD - PAYU SALES'
UPDATE HGMX_PAYU_Cash_JE SET UNIQUEID = 'HGMXPU' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PAYU_JE', @InsertFromTableName = 'HGMX_PAYU_Cash_JE'

SELECT
	CHECKBOOKID
	, SUM(DEBIT) DEBIT
	, SUM(CREDIT) CREDIT
INTO
	HGMX_PAYU_Total_Cash
FROM
	HGMX_PAYU_JE
WHERE
	LEFT(DISTREF, 9) = 'HGMX CASH'
GROUP BY 
	CHECKBOOKID

ALTER TABLE HGMX_PAYU_Total_Cash
 ADD DOCAMT_CALC DECIMAL(15,2)

UPDATE HGMX_PAYU_Total_Cash SET DOCAMT_CALC = DEBIT - CREDIT

ALTER TABLE HGMX_PAYU_JE
 ADD CASHRCPT VARCHAR(50)
 	, DISTYPE VARCHAR(50)
 	, DOCAMT DECIMAL(15,2)

UPDATE HGMX_PAYU_JE SET DOCAMT = (SELECT DOCAMT_CALC FROM HGMX_PAYU_Total_Cash)
UPDATE HGMX_PAYU_JE SET CASHRCPT = 'HGMXPUCR' + FORMAT(GETDATE(), 'MMddyyhhmm')
UPDATE HGMX_PAYU_JE SET DISTYPE = (CASE WHEN ACCOUNT IN ('061-10030-000') THEN '1' ELSE '3' END)

SELECT * INTO HGMX_PAYU_JE_Final FROM HGMX_PAYU_JE
SELECT * INTO HGMX_PAYU_Exception_Report FROM HGMX_GT_PAYU_FullOuterJoin
	WHERE zOther_Diff <> 0

-- Export the following tables --

--SELECT * FROM HGMX_PAYU_JE_Final
--SELECT * FROM HGMX_PAYU_Exception_Report
