USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_DLOCAL_SALES]    Script Date: 8/28/2020 3:01:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[HGMX_DLOCAL_SALES] @vDate VARCHAR(15) AS

EXEC HGMX_DROPS

--DECLARE @vDate VARCHAR(15)
--SET @vDate = '20200602'

DECLARE @vDate_Datetime DATETIME
SET @vDate_Datetime = @vDate

DECLARE @DLOCAL_DATE VARCHAR(15)
SET @DLOCAL_DATE = FORMAT(DATEADD(dd, 1, @vDate_Datetime), 'yyyyMMdd')

DECLARE @vDate_YYYY_MM_DD VARCHAR(15)
SET @vDate_YYYY_MM_DD = FORMAT(@vDate_Datetime, 'yyyy-MM-dd')

-- All Tables:
-- 1) HGMX_GT: all GT txns for one day.
-- 2) HGMX_DLOCAL: all dlocal txns for one day.
-- 3) HGMX_Summ_Rev: Summary of the Revenue according to the GT for one day
	--COMMENT Summarize Get Transaction data by Company, Type, Business Line and Settled By. Use only DLocal and Domestic AMEX data.

SELECT *
INTO HGMX_GT
FROM GT_Processed_HG_Mexico_New
WHERE Date = @vDate_YYYY_MM_DD 
--	AND	SettledBy_CALC = 'DLocal'

ALTER TABLE HGMX_GT
ADD	zVIND_GT VARCHAR(50)
	,DLOCAL_TXN_ID VARCHAR(150)
	,VIND_TXN_ID VARCHAR(50)
--	, COMPANY_CALC VARCHAR(55)

-- Importing DLocal Txns for one day

SELECT *
INTO HGMX_DLOCAL
FROM GTStage.dbo.GT_Processed_dLocal_all_transactions
WHERE ROW_TYPE IN ('TX')
	AND	LEFT(file_name, 8) = @DLOCAL_DATE
	AND	CAST(CREATION_DATE AS DATE) = CAST(@vDate_Datetime AS DATE)
	AND	STATUS = 'cleared'
	AND	BANK_MID = '2049'

ALTER TABLE HGMX_DLOCAL
ADD	FEES_CALC DECIMAL(15,2)
	, COMPANY_CALC VARCHAR(100)
	, NET_AMT_USD_CALC DECIMAL(15,2)

UPDATE HGMX_DLOCAL
 SET NET_AMT_USD_CALC = (
		CASE 
		WHEN TYPE = 'CREDIT'
		THEN - 1 * NET_SETTLEMENT_AMOUNT
		ELSE NET_SETTLEMENT_AMOUNT
		END
	);

UPDATE HGMX_DLOCAL SET FEES_CALC = PROCESSING_FEE_AMOUNT * -1;
UPDATE HGMX_DLOCAL SET COMPANY_CALC = 'HGMX'

-- Joining DLOCAL Merchant Report to GT on 'invoice_id' in GT and on 'Transaction_ID' in DLOCAL Merchant Report.

UPDATE HGMX_GT 
SET DLOCAL_TXN_ID = ISNULL(B.TRANSACTION_ID, '')
FROM HGMX_GT A
LEFT JOIN GTStage.dbo.GT_Processed_dLocal_all_transactions B
ON A.invoice_id = B.TRANSACTION_ID

UPDATE HGMX_GT SET COMPANY_CALC = 'HGMX'


SELECT COMPANY_CALC
	,TYPE_CALC
	,BUSINESS_LINE_CALC
	,SETTLEDBY_CALC
	,SUM(REVENUE_Amount_USD_CALC) AS REVENUE_Amount_USD_CALC
	,@vDate AS zIMPORT_DATE
INTO HGMX_GT_Summ_Rev
FROM HGMX_GT
WHERE SettledBy_CALC = 'DLocal'
GROUP BY COMPANY_CALC
	,TYPE_CALC
	,BUSINESS_LINE_CALC
	,SETTLEDBY_CALC

-- HGMX Company Code: 061
-- Company Calc: 'HGMX'
-- Unique ID: 'HGMXDL'

-- Start of DLOCAL GT Revenue JE
ALTER TABLE HGMX_GT_Summ_Rev ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(150), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), Table_name VARCHAR(120)

UPDATE HGMX_GT_Summ_Rev SET Table_name = 'HGMX_GT_Summ_Rev'
UPDATE HGMX_GT_Summ_Rev SET CHECKBOOKID = 'Operating'
UPDATE HGMX_GT_Summ_Rev SET ACCOUNT = ISNULL(B.Account_Num, '')
FROM HGMX_GT_Summ_Rev A
LEFT JOIN GTStage_Matt.dbo.hgmx_accounts_matrix_v2 B
ON A.COMPANY_CALC = B.Company_Calc
AND A.TYPE_CALC = B.Type_Calc
AND A.Business_Line_CALC = B.Business_Line_Calc

UPDATE HGMX_GT_Summ_Rev SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_GT_Summ_Rev SET TRANTYPE = 5
UPDATE HGMX_GT_Summ_Rev SET TRANDATE = FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_GT_Summ_Rev SET SRCDOC = 'ACL'
UPDATE HGMX_GT_Summ_Rev SET CURRID = 'Z-US$'
UPDATE HGMX_GT_Summ_Rev SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE DLOCAL';
UPDATE HGMX_GT_Summ_Rev SET DEBIT = (CASE WHEN REVENUE_Amount_USD_CALC > 0 THEN 0 ELSE REVENUE_Amount_USD_CALC * - 1 END)
UPDATE HGMX_GT_Summ_Rev SET CREDIT = (CASE WHEN REVENUE_Amount_USD_CALC < 0 THEN 0 ELSE REVENUE_Amount_USD_CALC END);
UPDATE HGMX_GT_Summ_Rev SET DISTREF = COMPANY_CALC + ' ' + TYPE_CALC + ' ' + Business_Line_CALC + ' - ' + SETTLEDBY_CALC + ' SALES';
UPDATE HGMX_GT_Summ_Rev SET KEY1 = '';
UPDATE HGMX_GT_Summ_Rev SET REVERSEDATE = '';
UPDATE HGMX_GT_Summ_Rev SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime, 'MMddyyyy');

SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
INTO HGMX_DLOCAL_JE
FROM HGMX_GT_Summ_Rev;

-- Summarize Taxes from GT:
SELECT
	COMPANY_CALC
	,SETTLEDBY_CALC
	,TAX_TYPE_CALC
	,SUM(TAX_Amount_USD_CALC) AS TAX_Amount_USD_CALC
INTO HGMX_GT_Summ_Tax
FROM HGMX_GT
WHERE SETTLEDBY_CALC = 'DLOCAL'
GROUP BY
	COMPANY_CALC
	, SETTLEDBY_CALC
	, TAX_TYPE_CALC

--COMMENT Build fields for Journal Entry
ALTER TABLE HGMX_GT_Summ_Tax ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50),  table_name varchar(55)
-- Old CHECKBOOKID was called: 'HGMX CHECKBOOK ID'

UPDATE HGMX_GT_Summ_Tax SET table_name = 'HGMX_GT_Summ_Tax'
UPDATE HGMX_GT_Summ_Tax SET CHECKBOOKID = 'Operating'
UPDATE HGMX_GT_Summ_Tax SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_GT_Summ_Tax SET TRANTYPE = 5
UPDATE HGMX_GT_Summ_Tax SET TRANDATE = FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_GT_Summ_Tax SET SRCDOC = 'ACL'
UPDATE HGMX_GT_Summ_Tax SET CURRID = 'Z-US$';
UPDATE HGMX_GT_Summ_Tax SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE DLOCAL';
UPDATE HGMX_GT_Summ_Tax SET ACCOUNT = (
		CASE 
			WHEN COMPANY_CALC = 'HGMX' AND TAX_TYPE_CALC = 'VAT' THEN '061-24910-000'
			WHEN COMPANY_CALC = 'HGMX' AND (TAX_TYPE_CALC = 'IST' OR TAX_TYPE_CALC = 'GST')	THEN '061-24940-000'
			WHEN COMPANY_CALC = 'HGMX' AND TAX_TYPE_CALC = 'UST' THEN '061-21300-000'
			ELSE 'XXX-XXXXX-XXX'
		END)

UPDATE HGMX_GT_Summ_Tax SET DEBIT = (CASE WHEN TAX_Amount_USD_CALC > 0 THEN 0 ELSE TAX_Amount_USD_CALC * - 1 END)
UPDATE HGMX_GT_Summ_Tax SET CREDIT = (CASE WHEN TAX_Amount_USD_CALC < 0 THEN 0 ELSE TAX_Amount_USD_CALC END)
UPDATE HGMX_GT_Summ_Tax SET DISTREF = COMPANY_CALC + ' ' + SETTLEDBY_CALC + ' - ' + TAX_TYPE_CALC + ' PAYABLE';
UPDATE HGMX_GT_Summ_Tax SET KEY1 = ''
UPDATE HGMX_GT_Summ_Tax SET REVERSEDATE = ''
UPDATE HGMX_GT_Summ_Tax SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime, 'MMddyyyy');

INSERT INTO HGMX_DLOCAL_JE (CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
FROM HGMX_GT_Summ_Tax WHERE ABS(TAX_Amount_USD_CALC) > 0

-- Now summarizing Fees from DLOCAL Txns report

SELECT
	COMPANY_CALC
	,SUM(FEES_CALC) AS FEES_CALC
INTO HGMX_DLOCAL_FEES
FROM HGMX_DLOCAL
WHERE FEES_CALC != 0
GROUP BY COMPANY_CALC;

ALTER TABLE HGMX_DLOCAL_FEES ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), table_name varchar(55)
UPDATE HGMX_DLOCAL_FEES SET table_name = 'HGMX_DLOCAL_FEES'
UPDATE HGMX_DLOCAL_FEES SET CHECKBOOKID = 'Operating'
UPDATE HGMX_DLOCAL_FEES SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_FEES SET TRANTYPE = 5;
UPDATE HGMX_DLOCAL_FEES SET TRANDATE = FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_FEES SET SRCDOC = 'ACL'
UPDATE HGMX_DLOCAL_FEES SET CURRID = 'Z-US$'
UPDATE HGMX_DLOCAL_FEES SET REFERENCE = FORMAT(@vDate_Datetime,'MMddyyyy') + ' REVENUE DLOCAL'
UPDATE HGMX_DLOCAL_FEES SET ACCOUNT = (
			CASE 
			WHEN COMPANY_CALC = 'HGMX'
				THEN '061-57000-590'
			ELSE 'XXX-XXXXX-XXX'
			END);
UPDATE HGMX_DLOCAL_FEES SET DEBIT = (CASE WHEN FEES_CALC < 0 THEN FEES_CALC * - 1 ELSE 0 END)
UPDATE HGMX_DLOCAL_FEES SET CREDIT = (CASE WHEN FEES_CALC > 0 THEN FEES_CALC ELSE 0 END)
UPDATE HGMX_DLOCAL_FEES SET DISTREF = COMPANY_CALC + ' - DLOCAL PROCESSING FEES'
UPDATE HGMX_DLOCAL_FEES SET KEY1 = ''
UPDATE HGMX_DLOCAL_FEES SET REVERSEDATE = ''
UPDATE HGMX_DLOCAL_FEES SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime, 'MMddyyyy')

INSERT INTO HGMX_DLOCAL_JE(CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name FROM HGMX_DLOCAL_FEES

-- Start of DLOCAL Exception Reports

SELECT *
INTO HGMX_GT_DLOCAL_FULLOUTERJOIN
FROM (SELECT
		 ISNULL(invoice_id, '') AS invoice_id
		, SettledBy_CALC
		, Currency
		, COMPANY_CALC AS COMPANY_CALC_GT
		, zVIND_GT
		, SUM(TRANS_AMOUNT_USD_CALC) AS 'TRANS_AMOUNT_USD_CALC'
		, SUM(TRANS_AMOUNT_LOCAL_CALC) AS  'TRANS_AMOUNT_LOCAL_CALC'
		, SUM(REVENUE_Amount_USD_CALC) AS 'REVENUE_Amount_USD_CALC'
		, SUM(REVENUE_Amount_LOCAL_CALC) AS  'REVENUE_Amount_LOCAL_CALC'
		, DATE AS 'GT_DATE'
	FROM HGMX_GT
	WHERE SETTLEDBY_CALC = 'dlocal'
	GROUP BY Invoice_id, SettledBy_CALC, Currency, COMPANY_CALC, DATE, zvind_GT) GT
FULL OUTER JOIN 
	(SELECT
		ISNULL(TRANSACTION_ID, '') as TRANSACTION_ID
		, COMPANY_CALC,Payment_type
		, PROCESSING_CURRENCY
		, ISNULL(PROCESSING_AMOUNT, 0) AS PROCESSING_AMOUNT
		, FX_RATE
		, ISNULL(NET_SETTLEMENT_AMOUNT, 0) AS NET_SETTLEMENT_AMOUNT
		, ISNULL(GROSS_SETTLEMENT_AMOUNT, 0) AS GROSS_SETTLEMENT_AMOUNT
		,PROCESSING_DATE
	FROM HGMX_DLOCAL) DLOCAL
ON DLOCAL.TRANSACTION_ID = GT.INVOICE_ID
AND PROCESSING_CURRENCY=CURRENCY

ALTER TABLE HGMX_GT_DLOCAL_FULLOUTERJOIN
ADD ZDIFF_USD DECIMAL(15,2),
	ZDIFF_ABS DECIMAL(15,2),
	ZOTHER_DIFF DECIMAL (15,2)
	, zFX_Diff DECIMAL(15,2)

UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN
 SET TRANS_AMOUNT_USD_CALC = (CASE
								WHEN TRANS_AMOUNT_USD_CALC IS NULL THEN 0
								ELSE TRANS_AMOUNT_USD_CALC
								END)

UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN
 SET TRANS_AMOUNT_LOCAL_CALC = (CASE
								WHEN TRANS_AMOUNT_LOCAL_CALC IS NULL THEN 0
								ELSE TRANS_AMOUNT_LOCAL_CALC
								END)

UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN
 SET NET_SETTLEMENT_AMOUNT = (CASE
								WHEN NET_SETTLEMENT_AMOUNT IS NULL THEN 0
								ELSE NET_SETTLEMENT_AMOUNT
								END)

UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN
 SET GROSS_SETTLEMENT_AMOUNT = (CASE 
								WHEN GROSS_SETTLEMENT_AMOUNT IS NULL THEN 0
								ELSE GROSS_SETTLEMENT_AMOUNT
								END)

UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN
 SET PROCESSING_AMOUNT = (CASE 
								WHEN PROCESSING_AMOUNT IS NULL THEN 0
								ELSE PROCESSING_AMOUNT
								END)


UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN SET ZDIFF_USD = TRANS_AMOUNT_USD_CALC - GROSS_SETTLEMENT_AMOUNT
UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN SET ZDIFF_ABS = ABS(ZDIFF_USD)
UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN SET ZFX_DIFF = 
			(CASE 
				WHEN TRANS_AMOUNT_LOCAL_CALC = PROCESSING_AMOUNT THEN TRANS_AMOUNT_USD_CALC - GROSS_SETTLEMENT_AMOUNT
				ELSE 0
			 END)
UPDATE HGMX_GT_DLOCAL_FULLOUTERJOIN SET ZOTHER_DIFF = ZDIFF_USD - ZFX_DIFF


-- Creating FX Adjustment Journal Entry
SELECT
	COMPANY_CALC
	, PROCESSING_CURRENCY
	, SUM(ZFX_DIFF) ZFX_DIFF
INTO
	HGMX_DLOCAL_FX_ADJ
FROM
	HGMX_GT_DLOCAL_FULLOUTERJOIN
GROUP BY
	COMPANY_CALC
	, PROCESSING_CURRENCY

ALTER TABLE HGMX_DLOCAL_FX_ADJ ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), table_name VARCHAR(55);

UPDATE HGMX_DLOCAL_FX_ADJ SET table_name = 'HGMX_DLOCAL_FX_ADJ'
UPDATE HGMX_DLOCAL_FX_ADJ SET CHECKBOOKID = 'Operating'
UPDATE HGMX_DLOCAL_FX_ADJ SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_FX_ADJ SET TRANTYPE = 5
UPDATE HGMX_DLOCAL_FX_ADJ SET TRANDATE = FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_FX_ADJ SET SRCDOC = 'ACL'
UPDATE HGMX_DLOCAL_FX_ADJ SET CURRID = 'Z-US$'
UPDATE HGMX_DLOCAL_FX_ADJ SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE DLOCAL';
UPDATE HGMX_DLOCAL_FX_ADJ SET ACCOUNT = 'xxx-xxxxx-xxx'
UPDATE HGMX_DLOCAL_FX_ADJ SET DEBIT = (CASE WHEN ZFX_DIFF < 0 THEN 0 ELSE ZFX_DIFF END)
UPDATE HGMX_DLOCAL_FX_ADJ SET CREDIT = (CASE WHEN ZFX_DIFF > 0 THEN 0 ELSE ZFX_DIFF * -1 END)
UPDATE HGMX_DLOCAL_FX_ADJ SET DISTREF = COMPANY_CALC + ' (UNREALIZED (GAIN) LOSS) ' + PROCESSING_CURRENCY
UPDATE HGMX_DLOCAL_FX_ADJ SET KEY1 = '';
UPDATE HGMX_DLOCAL_FX_ADJ SET REVERSEDATE = ''
UPDATE HGMX_DLOCAL_FX_ADJ SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime,'MMddyyyy')

INSERT INTO HGMX_DLOCAL_JE (CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
FROM HGMX_DLOCAL_FX_ADJ WHERE ABS(ZFX_DIFF) > 0


-- Begin building DLOCAL Suspense JE from Exception Report Table
SELECT * INTO HGMX_DLOCAL_EXCEPTION_REPORT
FROM HGMX_GT_DLOCAL_FULLOUTERJOIN
WHERE zFX_Diff = 0
	AND ZOTHER_DIFF <> 0

ALTER TABLE HGMX_DLOCAL_EXCEPTION_REPORT ADD
	EXCEPTION_NUM NUMERIC IDENTITY
	, EXCEPTION_ID VARCHAR(50)
	, ALL_COMPANY VARCHAR(50)
	
UPDATE HGMX_DLOCAL_EXCEPTION_REPORT SET EXCEPTION_ID = 'GT VERSUS DLOCAL EXCEPTION# - ' + CAST(EXCEPTION_NUM AS VARCHAR)
UPDATE HGMX_DLOCAL_EXCEPTION_REPORT SET ALL_COMPANY = (CASE WHEN COMPANY_CALC_GT IS NOT NULL THEN COMPANY_CALC_GT ELSE COMPANY_CALC END) 

 --(CASE WHEN BRAND IS NOT NULL THEN BRAND ELSE COMPANY_CALC END);
 
SELECT 
	ALL_COMPANY
	,SUM(ZOTHER_DIFF)ZOTHER_DIFF
INTO HGMX_DLOCAL_Summ_Exceptions
FROM HGMX_DLOCAL_EXCEPTION_REPORT
GROUP BY ALL_COMPANY;

ALTER TABLE HGMX_DLOCAL_Summ_Exceptions ADD CHECKBOOKID VARCHAR(50), BATCHID  VARCHAR(50), TRANTYPE  VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC  VARCHAR(50), CURRID  VARCHAR(50), REFERENCE  VARCHAR(50), ACCOUNT  VARCHAR(50), DEBIT DECIMAL(15,2), CREDIT DECIMAL(15,2), DISTREF  VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE  VARCHAR(50), UNIQUEID  VARCHAR(50) ,table_name varchar(55)

UPDATE HGMX_DLOCAL_Summ_Exceptions SET table_name = 'HGMX_DLOCAL_Summ_Exceptions'
UPDATE HGMX_DLOCAL_Summ_Exceptions SET CHECKBOOKID = 'Operating'
UPDATE HGMX_DLOCAL_Summ_Exceptions SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime,'MMddyyyy');
UPDATE HGMX_DLOCAL_Summ_Exceptions SET TRANTYPE = 5;
UPDATE HGMX_DLOCAL_Summ_Exceptions SET TRANDATE = FORMAT(@vDate_Datetime,'MMddyyyy');
UPDATE HGMX_DLOCAL_Summ_Exceptions SET SRCDOC = 'ACL';
UPDATE HGMX_DLOCAL_Summ_Exceptions SET CURRID = 'Z-US$';
UPDATE HGMX_DLOCAL_Summ_Exceptions SET REFERENCE = FORMAT(@vDate_Datetime,'MMddyyyy') + ' REVENUE DLOCAL'
UPDATE HGMX_DLOCAL_Summ_Exceptions SET ACCOUNT = '061-11045-000'		
UPDATE HGMX_DLOCAL_Summ_Exceptions SET DEBIT = (CASE WHEN ZOTHER_DIFF < 0 THEN 0 ELSE ZOTHER_DIFF END)
UPDATE HGMX_DLOCAL_Summ_Exceptions SET CREDIT = (CASE WHEN ZOTHER_DIFF > 0 THEN 0 ELSE ZOTHER_DIFF * -1 END)
UPDATE HGMX_DLOCAL_Summ_Exceptions SET DISTREF = ALL_COMPANY + ' A/R SUSPENSE (DLOCAL)'
UPDATE HGMX_DLOCAL_Summ_Exceptions SET KEY1 = ''
UPDATE HGMX_DLOCAL_Summ_Exceptions SET REVERSEDATE = ''
UPDATE HGMX_DLOCAL_Summ_Exceptions SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime,'MMddyyyy')

INSERT INTO HGMX_DLOCAL_JE (CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID ,table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID ,table_name FROM HGMX_DLOCAL_Summ_Exceptions

-- Create subset of DLOCAL report specifically for Chargebacks since data formatting in this table is slightly different between Transactions and CBacks.

SELECT *
INTO HGMX_DLOCAL_CBACKS
FROM GTSTAGE.dbo.GT_Processed_dLocal_all_transactions
WHERE row_type = 'CB'
	AND left(file_name, 8) = @DLOCAL_DATE
	and  BANK_MID = '2049';

ALTER TABLE HGMX_DLOCAL_CBACKS
 ADD COMPANY_CALC VARCHAR(50)
	,NET_AMT_USD_CALC DECIMAL(15, 2)

UPDATE HGMX_DLOCAL_CBACKS SET company_calc = 'HGMX'
UPDATE HGMX_DLOCAL_CBACKS SET NET_AMT_USD_CALC = (
			CASE 
			WHEN TYPE = 'CREDIT'
			THEN - 1 * (dispute_settlement_amount + dispute_fee)
			ELSE dispute_settlement_amount + dispute_fee
			END);

SELECT
	COMPANY_CALC
	,SUM(NET_AMT_USD_CALC) NET_AMT_USD_CALC
INTO HGMX_DLOCAL_CBacks_Summ
FROM HGMX_DLOCAL_CBACKS
GROUP BY COMPANY_CALC;

ALTER TABLE HGMX_DLOCAL_CBacks_Summ ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), table_name varchar(55)

UPDATE HGMX_DLOCAL_CBacks_Summ SET table_name = 'HGMX_DLOCAL_CBacks_Summ'
UPDATE HGMX_DLOCAL_CBacks_Summ SET CHECKBOOKID = 'Operating'
UPDATE HGMX_DLOCAL_CBacks_Summ SET BATCHID = 'ACL_' + format(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_CBacks_Summ SET TRANTYPE = 5
UPDATE HGMX_DLOCAL_CBacks_Summ SET TRANDATE = format(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_DLOCAL_CBacks_Summ SET SRCDOC = 'ACL'
UPDATE HGMX_DLOCAL_CBacks_Summ SET CURRID = 'Z-US$'
UPDATE HGMX_DLOCAL_CBacks_Summ SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE DLOCAL'
UPDATE HGMX_DLOCAL_CBacks_Summ SET ACCOUNT = (CASE WHEN COMPANY_CALC = 'HGMX' THEN '061-11035-000' ELSE 'XXX-XXXXX-XXX' END)
UPDATE HGMX_DLOCAL_CBacks_Summ SET DEBIT = (CASE WHEN NET_AMT_USD_CALC < 0 THEN NET_AMT_USD_CALC * - 1 ELSE 0 END)
UPDATE HGMX_DLOCAL_CBacks_Summ SET CREDIT = (CASE WHEN NET_AMT_USD_CALC > 0	THEN NET_AMT_USD_CALC ELSE 0 END)
UPDATE HGMX_DLOCAL_CBacks_Summ SET DISTREF = COMPANY_CALC + ' - CHARGEBACK SUSPENSE'
UPDATE HGMX_DLOCAL_CBacks_Summ SET KEY1 = ''
UPDATE HGMX_DLOCAL_CBacks_Summ SET REVERSEDATE = ''
UPDATE HGMX_DLOCAL_CBacks_Summ SET UNIQUEID = 'HGMXDL' + FORMAT(@vDate_Datetime, 'MMddyyyy')

INSERT INTO HGMX_DLOCAL_JE (CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name FROM HGMX_DLOCAL_CBacks_Summ


-- Lastly, building out A/R entry.
SELECT
	COMPANY_CALC
	,CAST(CREATION_DATE as DATE) AS DL_CREATION_DATE
	,SUM(NET_SETTLEMENT_AMOUNT) AS DL_NET_SETTLE_AMT
INTO DLOCAL_AR_Summ_Temp
FROM HGMX_DLOCAL
WHERE CREATION_DATE IS NOT NULL
GROUP BY
	COMPANY_CALC
	,CAST(CREATION_DATE AS DATE);

SELECT
	COMPANY_CALC
	,CAST(CREATION_DATE AS DATE) AS DL_CREATION_DATE
	,SUM(NET_AMT_USD_CALC) AS NET_CB_AMT_CALC
INTO DLOCAL_AR_Summ_Cbacks
FROM HGMX_DLOCAL_CBACKS
--WHERE CREATION_DATE IS NOT NULL
GROUP BY COMPANY_CALC
	,CAST(CREATION_DATE as date);

SELECT a.company_calc
	,CAST(a.DL_CREATION_DATE as date) as DL_CREATION_DATE
	,a.DL_NET_SETTLE_AMT 
	,b.company_calc AS company_calc_CB
	,b.NET_CB_AMT_CALC
INTO DLOCAL_AR_Summ
FROM DLOCAL_AR_Summ_Temp a
FULL JOIN DLOCAL_AR_Summ_Cbacks b ON a.company_calc = b.company_calc
	--AND cast(a.ACT_DATE_FOR_GT_CALC as date) = cast(b.ACT_DATE_FOR_GT_CALC as date);

ALTER TABLE DLOCAL_AR_Summ
 ADD ALL_COMPANY VARCHAR(50)
	,NET_AMT_USD_CALC DECIMAL(15,2)
	,AR_CALC DECIMAL(15, 2)

UPDATE DLOCAL_AR_Summ
 SET ALL_COMPANY = (
			CASE 
			WHEN COMPANY_CALC IS NOT NULL
			THEN COMPANY_CALC
			ELSE company_calc_CB
			END)

UPDATE DLOCAL_AR_Summ SET NET_AMT_USD_CALC = ISNULL(DL_NET_SETTLE_AMT, 0) + ISNULL(NET_CB_AMT_CALC, 0)
UPDATE DLOCAL_AR_Summ SET AR_CALC = NET_AMT_USD_CALC

SELECT 
	ALL_COMPANY AS COMPANY_CALC
	,SUM(AR_CALC) AR_CALC
INTO HGMX_AR_JE
FROM DLOCAL_AR_Summ
GROUP BY ALL_COMPANY

ALTER TABLE HGMX_AR_JE ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(50), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), table_name VARCHAR(55)

UPDATE HGMX_AR_JE SET table_name = 'HGMX_AR_JE'
UPDATE HGMX_AR_JE SET CHECKBOOKID = 'Operating'
UPDATE HGMX_AR_JE SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_AR_JE SET TRANTYPE = 5
UPDATE HGMX_AR_JE SET TRANDATE = FORMAT(@vDate_Datetime,'MMddyyyy')
UPDATE HGMX_AR_JE SET SRCDOC = 'ACL'
UPDATE HGMX_AR_JE SET CURRID = 'Z-US$'
UPDATE HGMX_AR_JE SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE DLOCAL'
UPDATE HGMX_AR_JE SET ACCOUNT = '061-11001-000'		
UPDATE HGMX_AR_JE SET DEBIT = (CASE WHEN AR_CALC > 0 THEN AR_CALC ELSE 0 END)
UPDATE HGMX_AR_JE SET CREDIT = (CASE WHEN AR_CALC < 0 THEN - 1 * AR_CALC ELSE 0 END);
UPDATE HGMX_AR_JE SET DISTREF = (CASE WHEN COMPANY_CALC = 'HGMX' THEN COMPANY_CALC + ' - ACCOUNTS RECEIVABLE (DLOCAL)' ELSE 'XXX - OTHER' END);
UPDATE HGMX_AR_JE SET KEY1 = ''
UPDATE HGMX_AR_JE SET REVERSEDATE = ''
UPDATE HGMX_AR_JE SET UNIQUEID = 'HGMXDL' + format(@vDate_Datetime, 'MMddyyyy');

INSERT INTO HGMX_DLOCAL_JE (CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
FROM HGMX_AR_JE;

-- Creation of final DLOCAL Sales JE table
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID
INTO HGMX_DLOCAL_SALES_JE_FINAL
FROM HGMX_DLOCAL_JE

-- All tables in order of appearance

--SELECT sum(revenue_amount_usd_calc)  FROM HGMX_GT
--SELECT sum(tax_amount_usd_calc)  FROM HGMX_GT
--SELECT sum(fees_calc) FROM HGMX_DLOCAL

--SELECT * FROM HGMX_GT_Summ_Rev
--SELECT * FROM HGMX_DLOCAL_JE
--SELECT * FROM HGMX_GT_Summ_Tax
--SELECT * FROM HGMX_DLOCAL_FEES
--SELECT * FROM HGMX_GT_DLOCAL_FULLOUTERJOIN
-- select sum(zfx_diff) from hgmx_gt_dlocal_fullouterjoin
--SELECT * FROM HGMX_DLOCAL_FX_ADJ

--SELECT sum(zother_diff) FROM HGMX_DLOCAL_EXCEPTION_REPORT
--SELECT * FROM HGMX_DLOCAL_Summ_Exceptions
--SELECT * FROM HGMX_DLOCAL_CBACKS
--SELECT * FROM HGMX_DLOCAL_CBacks_Summ
--SELECT * FROM DLOCAL_AR_Summ_Temp
--SELECT * FROM DLOCAL_AR_Summ_Cbacks
--SELECT * FROM DLOCAL_AR_Summ
--SELECT * FROM HGMX_AR_JE 

--SELECT * FROM HGMX_DLOCAL_JE
--SELECT * FROM HGMX_DLOCAL_SALES_JE_FINAL
