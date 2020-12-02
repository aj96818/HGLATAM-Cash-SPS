USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_PAYPAL_SALES]    Script Date: 12/2/2020 10:25:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- HGMX Paypal Sales Cash SPS
-- By: Alan Jackson
-- Created on: 8/26/2020

 ALTER PROCEDURE [dbo].[HGMX_PAYPAL_SALES] @vDate VARCHAR(25) AS
 --EXEC HGMX_DROPS

--DECLARE @vDate VARCHAR(50)
--SET @vDate = '20200802'

DECLARE @vDate_Datetime DATETIME
SET @vDate_Datetime = @vDate

DECLARE @vDate_MMddyyyy VARCHAR(20)
SET @vDate_MMddyyyy = FORMAT(@vDate_Datetime, 'MMddyyyy')

-- Summarize revenue from Paypal txns in GT Report

SELECT
	COMPANY_CALC
	, TYPE_CALC
	, BUSINESS_LINE_CALC
	, Currency
	, SUM(REVENUE_AMOUNT_USD_CALC) AS REVENUE_AMOUNT_USD_CALC
	, @vDate_MMddyyyy AS zPaypal_Date
INTO
	HGMX_Paypal_GT_Summ
FROM
	HGMX_GT
WHERE
	Settledby_Calc = 'Paypal'
GROUP BY
	COMPANY_CALC
	, TYPE_CALC
	, BUSINESS_LINE_CALC
	, Currency

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_Paypal_GT_Summ'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_Paypal_GT_Summ'
	, @CHECKBOOKID = 'PAYPAL'
	, @BATCHID = @vDate_MMddyyyy
	, @TRANTYPE = 5
	, @TRANDATE = @vDate_MMddyyyy

UPDATE A SET A.ACCOUNT = ISNULL(B.Account_Num, 'XXX-XXXXX-XXX')
FROM HGMX_Paypal_GT_Summ A
LEFT JOIN GTStage_Matt.dbo.hgmx_accounts_matrix_v2 B	ON A.TYPE_CALC = B.TYPE_CALC AND A.BUSINESS_LINE_CALC = B.BUSINESS_LINE_CALC;

UPDATE HGMX_Paypal_GT_Summ SET REFERENCE = zPaypal_Date + ' CASH PAYPAL'
UPDATE HGMX_Paypal_GT_Summ SET DEBIT = (CASE WHEN REVENUE_AMOUNT_USD_CALC > 0 THEN 0 ELSE REVENUE_AMOUNT_USD_CALC * -1 END)
UPDATE HGMX_Paypal_GT_Summ SET CREDIT = (CASE WHEN REVENUE_AMOUNT_USD_CALC < 0 THEN 0 ELSE REVENUE_AMOUNT_USD_CALC END )
UPDATE HGMX_Paypal_GT_Summ SET DISTREF = COMPANY_CALC + ' ' + TYPE_CALC + ' ' + BUSINESS_LINE_CALC + ' ' + Currency + ' - PAYPAL SALES'
UPDATE HGMX_Paypal_GT_Summ SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID INTO HGMX_PP_JE FROM HGMX_Paypal_GT_Summ


-- Summarize Tax collected from Paypal txns in GT report.
SELECT 
	COMPANY_CALC
	, Currency
	, TAX_TYPE_CALC
	, SUM(TAX_AMOUNT_USD_CALC) AS TAX_AMOUNT_USD_CALC
INTO HGMX_Paypal_GT_Tax_Summ
FROM HGMX_GT
WHERE Settledby_Calc = 'PAYPAL' AND TAX_AMOUNT_USD_CALC <> 0
GROUP BY 
	COMPANY_CALC
	, Currency
	, TAX_TYPE_CALC

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_Paypal_GT_Tax_Summ'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_Paypal_GT_Tax_Summ'
				, @CHECKBOOKID = 'PAYPAL'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_Paypal_GT_Tax_Summ SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYPAL'
UPDATE HGMX_Paypal_GT_Tax_Summ SET ACCOUNT = (CASE
		 WHEN TAX_TYPE_CALC = 'VAT' THEN '042-24910-000'
		 WHEN TAX_TYPE_CALC = 'UST' THEN '061-21120-000'
	 		ELSE '061-24940-000' END)
UPDATE HGMX_Paypal_GT_Tax_Summ SET DEBIT = (CASE WHEN TAX_AMOUNT_USD_CALC > 0 THEN 0 ELSE TAX_AMOUNT_USD_CALC * -1 END) 
UPDATE HGMX_Paypal_GT_Tax_Summ SET CREDIT = (CASE WHEN TAX_AMOUNT_USD_CALC < 0 THEN 0 ELSE TAX_AMOUNT_USD_CALC END)
UPDATE HGMX_Paypal_GT_Tax_Summ SET DISTREF = COMPANY_CALC + ' PAYPAL ' + Currency + ' - ' + TAX_TYPE_CALC + ' PAYABLE'
UPDATE HGMX_Paypal_GT_Tax_Summ SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PP_JE', @InsertFromTableName = 'HGMX_Paypal_GT_Tax_Summ'

--- Start summarizing HGMX Paypal Merchant Report to get Suspense, Fees, and Cback Journal Entries  ----

SELECT * INTO HGMX_Paypal
FROM GTStage.DBO.GT_Processed_Paypal_HGMX
WHERE FILE_NAME = 'STL-' + @vDate + '.01.009.CSV'
AND CH = 'SB'

ALTER TABLE HGMX_Paypal
 ADD zImport_Date VARCHAR(12)
 	, PP_Gross_Amt_CALC DECIMAL(15,2)
 	, PP_Fee_Amt_CALC DECIMAL(15,2)
 	, PP_Activity_Date VARCHAR(15)
 	, PP_Property_CALC VARCHAR(20)
 	, PP_TxnID_CALC VARCHAR(50)
 	, PP_Txn_Event_Type_CALC VARCHAR(150)
 	, PP_Txn_Event_Code_CALC VARCHAR(30)
 	, PP_Exclude_CALC VARCHAR(5)
 	, PP_Fee_Amt_USD_Calc DECIMAL(15,2)
 	, PP_FX_RATE_INVRS DECIMAL(10,4) 

UPDATE PP SET PP.PP_FX_RATE_INVRS = ISNULL(FX.InvrsRate_CALC, 1)
FROM HGMX_Paypal PP
LEFT JOIN [GTStage].[dbo].[GT_PROCESSED_EXCHANGERATE] FX ON FX.BASECURRENCYCODE = PP.Gross_Transaction_Currency
	AND CAST(PP.Transaction_Completion_Date AS DATE) = FX.DATECONVERSION

UPDATE HGMX_Paypal SET zImport_Date = @vDate
UPDATE HGMX_Paypal SET PP_Gross_Amt_CALC = (
	CASE WHEN Transaction_Debit_or_Credit = 'DR' THEN -1 * (Gross_Transaction_Amount / 100.00)
		ELSE Gross_Transaction_Amount / 100.00 END)
UPDATE HGMX_Paypal SET PP_Fee_Amt_CALC = (
	CASE WHEN Transaction_Debit_or_Credit = 'DR' THEN -1 * (CAST(Fee_Amount AS float) / 100.00)
		ELSE CAST(Fee_Amount AS float) / 100.00 END)

UPDATE HGMX_Paypal SET PP_Activity_Date = FORMAT(TRANSACTION_INITIATION_DATE, 'yyyyMMdd')
UPDATE HGMX_Paypal SET PP_Property_CALC = 'HGMX'
UPDATE HGMX_Paypal SET PP_Txn_Event_Code_CALC = SUBSTRING(Transaction_Event_Code, 1, 3)
UPDATE HGMX_Paypal SET PP_Txn_Event_Type_CALC = 
	(SELECT CASE PP_Txn_Event_Code_CALC
		WHEN 'T00' THEN 'Paypal to Paypal Payment'             
				WHEN 'T01' THEN 'Non-Payment Related Fees'             
				WHEN 'T02' THEN 'Currency Conversion'                  
				WHEN 'T03' THEN 'Bank Deposit into Paypal Acct'        
				WHEN 'T04' THEN 'Bank Withdrawal from Paypal Acct'     
				WHEN 'T05' THEN 'Debit Card'                           
				WHEN 'T06' THEN 'Credit Card Withdrawal'               
				WHEN 'T07' THEN 'Credit Card Deposit'                  
				WHEN 'T08' THEN 'Bonus'                                
				WHEN 'T09' THEN 'Incentive'                            
				WHEN 'T11' THEN 'Reversal'                             
				WHEN 'T12' THEN 'Adjustment'                           
				WHEN 'T13' THEN 'Authorization'                        
				WHEN 'T14' THEN 'Dividend'                             
				WHEN 'T15' THEN 'Hold For Dispute'                     
				WHEN 'T17' THEN 'Non-Bank Withdrawal'                  
				WHEN 'T18' THEN 'Buyer Credit Withdrawal'              
				WHEN 'T19' THEN 'Account Correction'                   
				WHEN 'T20' THEN 'Paypal to Paypal Funds Tfer'          
				WHEN 'T21' THEN 'Reserves and Releases'                
				ELSE '<Undefined>'
			END)

UPDATE HGMX_Paypal SET PP_Exclude_CALC = (
	CASE
		WHEN LEFT(Transaction_Event_Code, 3) = 'T02' THEN 'X'
		WHEN LEFT(Transaction_Event_Code, 3) = 'T04' THEN 'X'
		WHEN Transaction_Event_Code = 'T0000' THEN 'X'
		WHEN Transaction_Event_Code = 'T0001' THEN 'X'
		WHEN Transaction_Event_Code = 'T0104' THEN 'X'
		WHEN Transaction_Event_Code = 'T0600' THEN 'X'
		WHEN Transaction_Event_Code = 'T1105' THEN 'X'
		WHEN Transaction_Event_Code = 'T1116' THEN 'X'
		WHEN Transaction_Event_Code = 'T1503' THEN 'X'
		WHEN Transaction_Event_Code = 'T2103' THEN 'X'
		WHEN Transaction_Event_Code = 'T2104' THEN 'X'
		WHEN Transaction_Event_Code = 'T2105' THEN 'X'
		WHEN Transaction_Event_Code = 'T2106' THEN 'X'
		WHEN Transaction_Event_Code = 'T2001' THEN 'X'
			ELSE ''
	END)

UPDATE HGMX_Paypal SET PP_Fee_Amt_USD_Calc = ISNULL(Fee_Amount, 0) * PP_FX_RATE_INVRS
UPDATE HGMX_Paypal SET PP_TxnID_CALC = (CASE WHEN Transaction_ID IS NULL THEN ISNULL(Paypal_Reference_ID, '')
	ELSE Transaction_ID END)

-- Start building Paypal Exception Report --

	-- Summarize Paypal Txns in GT Report
SELECT * INTO HGMX_GT_PP_Suspense
FROM 
	(SELECT
		COMPANY_CALC
		, ISNULL(Unique_Trans_ID, '1') Unique_Trans_ID
		, Currency as GT_Currency
		, SUM(TRANS_AMOUNT_USD_CALC) GT_TRANS_AMT_USD_CALC
		, SUM(TRANS_AMOUNT_LOCAL_CALC) GT_TRANS_AMT_LOCAL_CALC
		, Date as GT_Date
	FROM HGMX_GT
	WHERE Settledby_Calc = 'PAYPAL'
	GROUP BY COMPANY_CALC, Unique_Trans_ID, Currency, Date) GT

	-- Summarize Paypal Txns in Paypal Merchant Report
SELECT
	PP_Property_CALC
	, PP_TxnID_CALC
	, Gross_Transaction_Currency as PP_Gross_Amt_Currency
	, SUM(PP_Gross_Amt_CALC) AS PP_Gross_Amt_CALC
	, SUM(ISNULL(PP_Fee_Amt_CALC, 0) * PP_FX_RATE_INVRS) AS PP_Fee_Amt_USD_Calc
	, Transaction_Event_Code
	, CAST(SUM(PP_Gross_Amt_CALC * PP_FX_RATE_INVRS) AS DECIMAL(15,2)) AS PP_Gross_Amt_USD_CALC
	, PP_FX_RATE_INVRS
	, PP_Exclude_CALC
	, CAST(PP_Activity_Date AS DATE) PP_Activity_Date
INTO HGMX_PP_Suspense
FROM HGMX_Paypal
GROUP BY
	PP_Property_CALC
	, PP_TxnID_CALC
	, Gross_Transaction_Currency
	, Transaction_Event_Code
	, PP_FX_RATE_INVRS
	, PP_Exclude_CALC
	, PP_Activity_Date

-- Join PP and GT reports at the same level of summarization to identify matched AND unmatched txns.
SELECT GT.*, PP.*
INTO HGMX_GT_Paypal_FullJoin
FROM HGMX_GT_PP_Suspense GT
FULL JOIN (SELECT * FROM HGMX_PP_Suspense WHERE PP_Exclude_CALC <> 'X') PP
	ON GT.Unique_Trans_ID = PP.PP_TxnID_CALC

-- Join PP and GT reports at the same level of summarization to identify exceptions.
SELECT GT.*, PP.*
INTO HGMX_GT_PP_FullOuterJoin
FROM HGMX_GT_PP_Suspense GT
FULL OUTER JOIN (SELECT * FROM HGMX_PP_Suspense WHERE PP_Exclude_CALC <> 'X') PP
	ON GT.Unique_Trans_ID = PP.PP_TxnID_CALC

ALTER TABLE HGMX_GT_PP_FullOuterJoin
 ADD zChargeback VARCHAR(25)
	, zCurrency_All VARCHAR(55)
 	, zCBack_Amount DECIMAL(15,2)
 	, zTrans_Amt_Diff DECIMAL(15,2)
 	, zFX_Diff DECIMAL(10,2)
 	, zOther_Diff DECIMAL(15,2)
 	, zAll_Company VARCHAR(50)

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zChargeback = (CASE WHEN Transaction_Event_Code IN ('T1106','T1201','T1202','T1110','T1111','T1114') THEN 'Yes' ELSE 'No' END)

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zCBack_Amount = (CASE WHEN zChargeback = 'Yes' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PP_Gross_Amt_USD_CALC, 0) ELSE 0 END) 

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zTrans_Amt_Diff = (CASE WHEN zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PP_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zFX_Diff = (CASE WHEN GT_TRANS_AMT_LOCAL_CALC = PP_Gross_Amt_CALC AND zChargeback = 'No' THEN ISNULL(GT_TRANS_AMT_USD_CALC, 0) - ISNULL(PP_Gross_Amt_USD_CALC, 0) ELSE 0 END)

UPDATE HGMX_GT_PP_FullOuterJoin SET zOther_Diff = zTrans_Amt_Diff - zFX_Diff

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zAll_Company = (CASE WHEN COMPANY_CALC IS NOT NULL THEN COMPANY_CALC ELSE PP_Property_CALC END)

UPDATE HGMX_GT_PP_FullOuterJoin 
SET zCurrency_All = (CASE WHEN GT_Currency IS NULL THEN PP_Gross_Amt_Currency ELSE GT_Currency END)

	-- Summarize Paypal Suspense for JE
SELECT 
	zAll_Company
	, zCurrency_All
	, SUM(zOther_Diff) AS Suspense_Amount
	, SUM(zFX_Diff) AS FX_Amount
	, SUM(zCBack_Amount) AS CBack_Amount
	, SUM(PP_Fee_Amt_USD_Calc) AS PP_Fee_Amt_USD_Calc
INTO HGMX_PP_Suspense_JE
FROM HGMX_GT_PP_FullOuterJoin
GROUP BY zAll_Company, zCurrency_All

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PP_Suspense_JE'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PP_Suspense_JE'
				, @CHECKBOOKID = 'PAYPAL'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy
UPDATE HGMX_PP_Suspense_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYPAL'
UPDATE HGMX_PP_Suspense_JE SET ACCOUNT = '061-11045-000'
UPDATE HGMX_PP_Suspense_JE SET DEBIT = (CASE WHEN Suspense_Amount > 0 THEN Suspense_Amount ELSE 0 END)
UPDATE HGMX_PP_Suspense_JE SET CREDIT = (CASE WHEN Suspense_Amount < 0 THEN Suspense_Amount * -1 ELSE 0 END)
UPDATE HGMX_PP_Suspense_JE SET DISTREF = zAll_Company + ' PAYPAL ' + zCurrency_All + ' SUSPENSE - PAYPAL SALES'
UPDATE HGMX_PP_Suspense_JE SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

IF (SELECT SUM(DEBIT) + SUM(CREDIT) FROM HGMX_PP_Suspense_JE) > 0 
BEGIN 
	EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PP_JE', @InsertFromTableName = 'HGMX_PP_Suspense_JE'
END

	-- End Paypal Exception JE; Start CBacks JE
SELECT
	zAll_Company
	, zCurrency_All
	, SUM(zCBack_Amount) CBack_Amount
INTO HGMX_PP_Cbacks_JE
FROM HGMX_GT_PP_FullOuterJoin
WHERE zChargeback = 'Yes'
GROUP BY zAll_Company, zCurrency_All

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PP_Cbacks_JE'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PP_Cbacks_JE'
				, @CHECKBOOKID = 'PAYPAL'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_PP_Cbacks_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYPAL'
UPDATE HGMX_PP_Cbacks_JE SET ACCOUNT = '061-11035-000'
UPDATE HGMX_PP_Cbacks_JE SET DEBIT = (CASE WHEN CBack_Amount > 0 THEN CBack_Amount ELSE 0 END)
UPDATE HGMX_PP_Cbacks_JE SET CREDIT = (CASE WHEN CBack_Amount < 0 THEN CBack_Amount * -1 ELSE 0 END)
UPDATE HGMX_PP_Cbacks_JE SET DISTREF = zAll_Company + ' CHARGEBACKS - PAYPAL ' + zCurrency_All + ' SALES'
UPDATE HGMX_PP_Cbacks_JE SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PP_JE', @InsertFromTableName = 'HGMX_PP_Cbacks_JE'

	-- End of Paypal Chargebacks JE; Start of Fees JE
SELECT
	zAll_Company
	, zCurrency_All
	, SUM(PP_Fee_Amt_USD_Calc) AS PP_Fee_Amt_USD_Calc 
INTO HGMX_PP_Fees_JE
FROM HGMX_GT_PP_FullOuterJoin
WHERE PP_Fee_Amt_USD_Calc <> 0
GROUP BY zAll_Company, zCurrency_All

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PP_Fees_JE'
EXEC spUpdateJE @TabletoUpdate = 'HGMX_PP_Fees_JE'
				, @CHECKBOOKID = 'PAYPAL'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_PP_Fees_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYPAL'
UPDATE HGMX_PP_Fees_JE SET ACCOUNT = '061-57000-590'
UPDATE HGMX_PP_Fees_JE SET DEBIT = (CASE WHEN PP_Fee_Amt_USD_Calc > 0 THEN PP_Fee_Amt_USD_Calc ELSE 0 END)
UPDATE HGMX_PP_Fees_JE SET CREDIT = (CASE WHEN PP_Fee_Amt_USD_Calc < 0 THEN PP_Fee_Amt_USD_Calc * -1 ELSE 0 END)
UPDATE HGMX_PP_Fees_JE SET DISTREF = zAll_Company + ' - PAYPAL ' + zCurrency_All + ' PROCESSING FEES'
UPDATE HGMX_PP_Fees_JE SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PP_JE', @InsertFromTableName = 'HGMX_PP_Fees_JE'

	-- End Fees; Start Cash JE
SELECT 
	CHECKBOOKID AS zCBOOKID
	, SUM(CREDIT) AS SUM_CREDIT
	, SUM(DEBIT) AS SUM_DEBIT
INTO HGMX_PP_Cash_JE
FROM HGMX_PP_JE
WHERE LEFT(DISTREF, 4) = 'HGMX'
GROUP BY CHECKBOOKID

EXEC spAddFieldstoJE @AlterTableName = 'HGMX_PP_Cash_JE'
ALTER TABLE HGMX_PP_Cash_JE
 ADD PLUG_CALC DECIMAL(15,2)
 	, CURRENCY_CALC VARCHAR(50)

UPDATE HGMX_PP_Cash_JE SET PLUG_CALC = (SUM_CREDIT - SUM_DEBIT)
UPDATE HGMX_PP_Cash_JE SET CURRENCY_CALC = CHECKBOOKID  

EXEC spUpdateJE @TabletoUpdate = 'HGMX_PP_Cash_JE'
				, @CHECKBOOKID = 'PAYPAL'
				, @BATCHID = @vDate_MMddyyyy
				, @TRANTYPE = 5
				, @TRANDATE = @vDate_MMddyyyy

UPDATE HGMX_PP_Cash_JE SET REFERENCE = @vDate_MMddyyyy + ' CASH PAYPAL'
UPDATE HGMX_PP_Cash_JE SET ACCOUNT = '042-10030-000'
UPDATE HGMX_PP_Cash_JE SET DEBIT = (CASE WHEN PLUG_CALC > 0 THEN PLUG_CALC ELSE 0 END)
UPDATE HGMX_PP_Cash_JE SET CREDIT = (CASE WHEN PLUG_CALC < 0 THEN PLUG_CALC * -1 ELSE 0 END)
UPDATE HGMX_PP_Cash_JE SET DISTREF = 'HGMX CASH USD - PAYPAL SALES'
UPDATE HGMX_PP_Cash_JE SET UNIQUEID = 'HGMXPP' + @vDate_MMddyyyy + @vDate_MMddyyyy

EXEC spInsertInto_Temp_JE @InsertIntoTableName = 'HGMX_PP_JE', @InsertFromTableName = 'HGMX_PP_Cash_JE'

SELECT
	CHECKBOOKID
	, SUM(DEBIT) DEBIT
	, SUM(CREDIT) CREDIT
INTO
	HGMX_PP_Total_Cash
FROM
	HGMX_PP_JE
WHERE
	LEFT(DISTREF, 9) = 'HGMX CASH'
GROUP BY 
	CHECKBOOKID

ALTER TABLE HGMX_PP_Total_Cash
 ADD DOCAMT_CALC DECIMAL(15,2)

UPDATE HGMX_PP_Total_Cash SET DOCAMT_CALC = DEBIT - CREDIT

ALTER TABLE HGMX_PP_JE
 ADD CASHRCPT VARCHAR(50)
 	, DISTYPE VARCHAR(50)
 	, DOCAMT DECIMAL(15,2)

UPDATE HGMX_PP_JE SET DOCAMT = (SELECT DOCAMT_CALC FROM HGMX_PP_Total_Cash)
UPDATE HGMX_PP_JE SET CASHRCPT = 'HGMXPPCR' + FORMAT(GETDATE(), 'MMddyyhhmm')
UPDATE HGMX_PP_JE SET DISTYPE = (CASE WHEN ACCOUNT IN ('061-10030-000') THEN '1' ELSE '3' END)

SELECT * INTO HGMX_PP_JE_Final FROM HGMX_PP_JE
SELECT * INTO HGMX_Paypal_Exception_Report FROM HGMX_GT_PP_FullOuterJoin
	WHERE zOther_Diff <> 0

-- Export the following tables --

--SELECT * FROM HGMX_PP_JE_Final
--SELECT * FROM HGMX_Paypal_Exception_Report
