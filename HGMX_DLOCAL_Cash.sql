USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_DLOCAL_CASH]    Script Date: 12/2/2020 10:21:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---HGMX DLOCAL CASH
-- Alan Jackson
-- 1/21/2020

ALTER   PROCEDURE [dbo].[HGMX_DLOCAL_CASH] @vdate varchar(50) as

--DECLARE @VDATE VARCHAR(50);
--SET @VDATE = '20190927';

DECLARE @VDATE2 DATETIME;
DECLARE @DLOCAL_DATE varchar(50);
--DECLARE @DLOCAL_DATE varchar(50);

SET @VDATE2 = @VDATE;
SET @DLOCAL_DATE = format(dateadd(dd,1,@VDATE2),'yyyyMMdd')
--SET @DLOCAL_DATE = format(@DLOCAL_DATE1,'yyyyMMdd')


IF OBJECT_ID('HGMX_DLOCAL_CASH_IMPORT', 'U') IS NOT NULL
	DROP TABLE HGMX_DLOCAL_CASH_IMPORT;

IF OBJECT_ID('HGMX_DLOCAL_CASH_TEMP', 'U') IS NOT NULL
	DROP TABLE HGMX_DLOCAL_CASH_TEMP;

IF OBJECT_ID('HGMX_DLocal_Summ_CASH', 'U') IS NOT NULL
	DROP TABLE HGMX_DLocal_Summ_CASH;


IF OBJECT_ID('HGMX_DLOCAL_CB_IMPORT', 'U') IS NOT NULL
	DROP TABLE HGMX_DLOCAL_CB_IMPORT;

IF OBJECT_ID('HGMX_DLOCAL_CB_TEMP', 'U') IS NOT NULL
	DROP TABLE HGMX_DLOCAL_CB_TEMP;

IF OBJECT_ID('HGMX_DLocal_CB_Summ_CASH', 'U') IS NOT NULL
	DROP TABLE HGMX_DLocal_CB_Summ_CASH;

IF OBJECT_ID('HGMX_DLocal_Summ_CASH_PRELIM', 'U') IS NOT NULL
	DROP TABLE HGMX_DLocal_Summ_CASH_PRELIM;

IF OBJECT_ID('HGMX_DLocal_Cash_JE', 'U') IS NOT NULL
	DROP TABLE HGMX_DLocal_Cash_JE;
	
IF OBJECT_ID('HGMX_DLOCALCASH_TOTAL', 'U') IS NOT NULL
	DROP TABLE HGMX_DLOCALCASH_TOTAL;


-- Start of importing Cash transactions from DLocal Settlement Report

SELECT * INTO HGMX_DLOCAL_CASH_IMPORT
FROM GTSTAGE.dbo.GT_Processed_Hostgator_Mexico_dLocal_Settlement 
WHERE LEFT(FILE_NAME,8) = @DLOCAL_DATE
AND ROW_TYPE = 'TX';


ALTER TABLE HGMX_DLOCAL_CASH_IMPORT
ADD TXN_ID_FOR_GT_CALC VARCHAR(50),
	ACT_DATE_FOR_GT_CALC DATE,
	COMPANY_CALC VARCHAR(50),
	GROSS_AMT_LOCAL_CALC DECIMAL(15,2),
	GROSS_AMT_USD_CALC DECIMAL(15,2),
	FEE_AMOUNT_USD_CALC DECIMAL(15,2),
	NET_AMT_USD_CALC DECIMAL(15,2),
	CURR_LOCAL_CALC VARCHAR(50);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET TXN_ID_FOR_GT_CALC = BANK_REFERENCE;

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET ACT_DATE_FOR_GT_CALC = CREATION_DATE;

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET COMPANY_CALC = 'HGMX'

-- (CASE
-- 	WHEN LEFT(TRANSACTION_ID,8) = 'BLUEHOST' THEN 'BLUEHOST'
-- 	WHEN LEFT(TRANSACTION_ID,8) = 'JUSTHOST' THEN 'JUSTHOST'
-- 	WHEN LEFT(TRANSACTION_ID,10) = 'FASTDOMAIN' THEN 'FASTDOMAIN'
-- 	WHEN LEFT(TRANSACTION_ID,11) = 'HOSTMONSTER' THEN 'HOSTMONSTER'
-- 	WHEN DESCRIPTION = 'HostMonster' THEN 'HOSTMONSTER'
-- 	WHEN DESCRIPTION = 'BlueHost' THEN 'BLUEHOST'
-- 	WHEN DESCRIPTION = 'JustHost' THEN 'JUSTHOST'
-- 	WHEN DESCRIPTION = 'FASTDOMAIN' THEN 'FASTDOMAIN'
-- 	ELSE 'BLUEHOST'
-- END);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET GROSS_AMT_LOCAL_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN PROCESSING_AMOUNT * -1
		ELSE PROCESSING_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET GROSS_AMT_USD_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN GROSS_SETTLEMENT_AMOUNT * -1
		ELSE GROSS_SETTLEMENT_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET FEE_AMOUNT_USD_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN PROCESSING_FEE_AMOUNT * -1
		ELSE PROCESSING_FEE_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET NET_AMT_USD_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN NET_SETTLEMENT_AMOUNT * -1
		ELSE NET_SETTLEMENT_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CASH_IMPORT
 SET CURR_LOCAL_CALC = PROCESSING_CURRENCY;

SELECT * INTO HGMX_DLOCAL_CASH_TEMP
FROM HGMX_DLOCAL_CASH_IMPORT ;


SELECT 
	COMPANY_CALC
	,ACT_DATE_FOR_GT_CALC
	,SUM(NET_AMT_USD_CALC) AS GROSS_STL_AMT_CALC
INTO HGMX_DLocal_Summ_CASH
FROM HGMX_DLOCAL_CASH_TEMP
WHERE ACT_DATE_FOR_GT_CALC IS NOT NULL
GROUP BY
	COMPANY_CALC
	,ACT_DATE_FOR_GT_CALC;



-- Select Chargeback txns from Settlement Report

SELECT * INTO HGMX_DLOCAL_CB_IMPORT
FROM GTSTAGE.dbo.GT_Processed_Hostgator_Mexico_dLocal_Settlement 
WHERE LEFT(FILE_NAME,8) = @DLOCAL_DATE
AND ROW_TYPE = 'CB';

ALTER TABLE HGMX_DLOCAL_CB_IMPORT
 ADD TXN_ID_FOR_GT_CALC VARCHAR(50),
	ACT_DATE_FOR_GT_CALC DATE,
	COMPANY_CALC VARCHAR(50),
	GROSS_AMT_LOCAL_CALC DECIMAL(15,2),
	GROSS_AMT_USD_CALC DECIMAL(15,2),
	FEE_AMT_USD_CALC DECIMAL(15,2),
	NET_AMT_USD_CALC DECIMAL(15,2),
	CURR_LOCAL_CALC VARCHAR(50);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET TXN_ID_FOR_GT_CALC = PROCESSOR_REFERENCE;

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET ACT_DATE_FOR_GT_CALC = DISPUTE_REGISTRATION_DATE;

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET COMPANY_CALC = 'HGMX'

-- (CASE
-- WHEN LEFT(ORIGINAL_TRANSACTION_REFERENCE,8)='BLUEHOST' THEN 'BLUEHOST'
-- WHEN LEFT(ORIGINAL_TRANSACTION_REFERENCE,8)='JUSTHOST' THEN 'JUSTHOST'
-- WHEN LEFT(ORIGINAL_TRANSACTION_REFERENCE,10)='FASTDOMAIN' THEN 'FASTDOMAIN'
-- WHEN LEFT(ORIGINAL_TRANSACTION_REFERENCE,11)='HOSTMONSTER' THEN 'HOSTMONSTER'
-- WHEN DESCRIPTION = 'HostMonster' THEN 'HOSTMONSTER'
-- WHEN DESCRIPTION = 'BlueHost' THEN 'BLUEHOST'
-- WHEN DESCRIPTION = 'JustHost' THEN 'JUSTHOST'
-- WHEN DESCRIPTION = 'FASTDOMAIN' THEN 'FASTDOMAIN'
-- ELSE 'BLUEHOST'
-- END);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET GROSS_AMT_LOCAL_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN DISPUTE_PROCESSING_AMOUNT * -1
		ELSE DISPUTE_PROCESSING_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET GROSS_AMT_USD_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN DISPUTE_SETTLEMENT_AMOUNT * -1
		ELSE DISPUTE_SETTLEMENT_AMOUNT
	END);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET FEE_AMT_USD_CALC =
	(CASE
		WHEN TYPE = 'CREDIT' THEN DISPUTE_FEE * -1
		ELSE DISPUTE_FEE
	END);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET NET_AMT_USD_CALC =
		(CASE
			WHEN TYPE = 'CREDIT' THEN (DISPUTE_SETTLEMENT_AMOUNT + DISPUTE_FEE) * -1
			ELSE DISPUTE_SETTLEMENT_AMOUNT + DISPUTE_FEE
		END);

UPDATE HGMX_DLOCAL_CB_IMPORT
 SET CURR_LOCAL_CALC = DISPUTE_SETTLEMENT_CURRENCY;


SELECT * INTO HGMX_DLOCAL_CB_TEMP
FROM HGMX_DLOCAL_CB_IMPORT
--WHERE COMPANY_CALC != 'OTHER';

SELECT
	COMPANY_CALC
	,ACT_DATE_FOR_GT_CALC
	,SUM(NET_AMT_USD_CALC) AS NET_CB_AMT
INTO HGMX_DLocal_CB_Summ_CASH
FROM HGMX_DLOCAL_CB_TEMP
WHERE ACT_DATE_FOR_GT_CALC IS NOT NULL
GROUP BY 
	COMPANY_CALC
	, ACT_DATE_FOR_GT_CALC;


SELECT 
	(CASE
		WHEN ISNULL(A.COMPANY_CALC, '') <> ''
			THEN A.COMPANY_CALC
		WHEN ISNULL(B.COMPANY_CALC, '') <> ''
			THEN B.COMPANY_CALC
	END) COMPANY_CALC
	,(CASE
		WHEN ISNULL(A.ACT_DATE_FOR_GT_CALC, '') <> ''
			THEN A.ACT_DATE_FOR_GT_CALC
		WHEN ISNULL(B.ACT_DATE_FOR_GT_CALC, '') <> ''
			THEN B.ACT_DATE_FOR_GT_CALC
	END) ACT_DATE_FOR_GT_CALC		
	,ISNULL(A.GROSS_STL_AMT_CALC,0) GROSS_STL_AMT_CALC
	,isnull(B.NET_CB_AMT,0) NET_CB_AMT
INTO HGMX_DLocal_Summ_CASH_PRELIM
FROM HGMX_DLocal_Summ_CASH A
FULL outer join HGMX_DLocal_CB_Summ_CASH B
ON A.COMPANY_CALC = B.COMPANY_CALC
AND A.ACT_DATE_FOR_GT_CALC = B.ACT_DATE_FOR_GT_CALC;

--COMMENT Build fields for Journal Entry

ALTER TABLE HGMX_DLocal_Summ_CASH_PRELIM
ADD NET_AMT_USD_CALC DECIMAL(15,2),
	CHECKBOOKID VARCHAR(50),
	BATCHID VARCHAR(50),
	TRANTYPE VARCHAR(50),
	TRANDATE VARCHAR(50),
	SRCDOC VARCHAR(50),
	CURRID VARCHAR(50),
	REFERENCE VARCHAR(50),
	ACCOUNT VARCHAR(50),
	DEBIT DECIMAL(15,2),
	CREDIT DECIMAL(15,2),	
	DISTREF VARCHAR(50),
	KEY1 VARCHAR(50),
	REVERSEDATE VARCHAR(50),
	UNIQUEID VARCHAR(50);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
 SET NET_AMT_USD_CALC = GROSS_STL_AMT_CALC + NET_CB_AMT;

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
 SET CHECKBOOKID = 'Operating';
-- (CASE
-- WHEN COMPANY_CALC= 'Fastdomain' THEN 'BOA-BH-MERCH'
-- WHEN COMPANY_CALC= 'Hostmonster' THEN 'BOA-HM-MERCH'
-- WHEN COMPANY_CALC= 'Justhost' THEN 'BOA-JH-MERCH'
-- ELSE 'BOA-BH-MERCH'
-- END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET BATCHID = 'ACL_' + FORMAT(@VDATE2,'MMddyyyy');
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET TRANTYPE = 5;
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET TRANDATE = FORMAT(@VDATE2,'MMddyyyy');
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET SRCDOC = 'ACL';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET CURRID = 'Z-US$';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET REFERENCE = FORMAT(@VDATE2,'MMddyyyy') + ' CASH DLOCAL'
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET ACCOUNT = '061-10005-000'
-- (CASE
-- WHEN COMPANY_CALC= 'Bluehost' THEN '008-10083-000'
-- WHEN COMPANY_CALC= 'Fastdomain' THEN '008-10083-000'
-- WHEN COMPANY_CALC= 'Hostmonster' THEN '008-10083-000'
-- WHEN COMPANY_CALC= 'Justhost' THEN '008-10083-000'
-- ELSE 'XXX-XXXXX-XXX'
-- END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
	SET DEBIT = (CASE WHEN NET_AMT_USD_CALC > 0 THEN NET_AMT_USD_CALC ELSE 0 END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM 
	SET CREDIT = (CASE WHEN NET_AMT_USD_CALC < 0 THEN NET_AMT_USD_CALC * -1 ELSE 0 END); 

UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET DISTREF = COMPANY_CALC + ' - CASH';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET KEY1 = '';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET REVERSEDATE = '';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET UNIQUEID = 'HGMXDL' + REPLACE(CAST(ACT_DATE_FOR_GT_CALC AS VARCHAR),'-','');

SELECT
	CHECKBOOKID
	,BATCHID
	,TRANTYPE
	,TRANDATE
	,SRCDOC
	,CURRID
	,REFERENCE
	,ACCOUNT
	,DEBIT
	,CREDIT
	,DISTREF
	,KEY1
	,REVERSEDATE
	,UNIQUEID
INTO HGMX_DLocal_Cash_JE
FROM HGMX_DLocal_Summ_CASH_PRELIM;


-- Add A/R entries which are essentially a mirror image of the Cash entries you just created.  Insert into final DLOCAL Cash JE

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
	SET CHECKBOOKID = 'Operating'
-- (CASE
-- WHEN COMPANY_CALC= 'Fastdomain' THEN 'BOA-BH-MERCH'
-- WHEN COMPANY_CALC= 'Hostmonster' THEN 'BOA-HM-MERCH'
-- WHEN COMPANY_CALC= 'Justhost' THEN 'BOA-JH-MERCH'
-- ELSE 'BOA-BH-MERCH'
-- END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET BATCHID = 'ACL_' + FORMAT(@VDATE2,'MMddyyyy');
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET TRANTYPE = 5;
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET TRANDATE = FORMAT(@VDATE2,'MMddyyyy');
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET SRCDOC = 'ACL';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET CURRID = 'Z-US$';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET REFERENCE = FORMAT(@VDATE2,'MMddyyyy') + ' CASH DLOCAL'
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET ACCOUNT = '061-11001-000'
-- (CASE
-- WHEN COMPANY_CALC= 'Bluehost' THEN '008-11001-000'
-- WHEN COMPANY_CALC= 'Fastdomain' THEN '008-11001-000'
-- WHEN COMPANY_CALC= 'Hostmonster' THEN '008-11001-000'
-- WHEN COMPANY_CALC= 'Justhost' THEN '008-11001-000'
-- ELSE 'XXX-XXXXX-XXX'
-- END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
	SET DEBIT = (CASE WHEN NET_AMT_USD_CALC < 0 THEN NET_AMT_USD_CALC * -1 ELSE 0 END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
	SET CREDIT = (CASE WHEN NET_AMT_USD_CALC > 0 THEN NET_AMT_USD_CALC ELSE 0 END);

UPDATE HGMX_DLocal_Summ_CASH_PRELIM
	SET DISTREF = COMPANY_CALC + ' - ACCOUNTS RECEIVABLE';

UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET KEY1 = '';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET REVERSEDATE = '';
UPDATE HGMX_DLocal_Summ_CASH_PRELIM SET UNIQUEID = 'HGMXDL' + REPLACE(CAST(ACT_DATE_FOR_GT_CALC AS VARCHAR),'-','');

INSERT INTO HGMX_DLocal_Cash_JE
(CHECKBOOKID,
BATCHID,
TRANTYPE,
TRANDATE,
SRCDOC,
CURRID,
REFERENCE,
ACCOUNT,
DEBIT,
CREDIT,
DISTREF,
KEY1,
REVERSEDATE,
UNIQUEID)
SELECT 
CHECKBOOKID,
BATCHID,
TRANTYPE,
TRANDATE,
SRCDOC,
CURRID,
REFERENCE,
ACCOUNT,
DEBIT,
CREDIT,
DISTREF,
KEY1,
REVERSEDATE,
UNIQUEID
FROM HGMX_DLocal_Summ_CASH_PRELIM


SELECT
	CHECKBOOKID
	, SUM(DEBIT) DEBIT
	, SUM(CREDIT) CREDIT
INTO HGMX_DLOCALCASH_TOTAL
FROM HGMX_DLocal_Summ_CASH_FINAL
WHERE DISTREF = 'HGMX - CASH'
GROUP BY CHECKBOOKID

ALTER TABLE HGMX_DLOCALCASH_TOTAL ADD vDOCAMTDLC DECIMAL(15,2);
UPDATE HGMX_DLOCALCASH_TOTAL SET vDOCAMTDLC = DEBIT - CREDIT;

ALTER TABLE HGMX_DLOCAL_CASH_JE
ADD DOCAMT DECIMAL(15,2),CASHRCPT VARCHAR(50),DISTYPE VARCHAR(50);

UPDATE HGMX_DLOCAL_CASH_JE SET DOCAMT = (SELECT vDOCAMTDLC FROM HGMX_DLOCALCASH_TOTAL)
UPDATE HGMX_DLOCAL_CASH_JE SET CASHRCPT = 'DCM' + FORMAT(GETDATE(), 'MMddyyyyhhmm')
UPDATE HGMX_DLOCAL_CASH_JE SET DISTYPE = (CASE WHEN ACCOUNT = '061-10083-000' THEN '1' ELSE '3' END)


--SELECT * FROM HGMX_DLocal_Cash_JE



--- Ad-hoc queries ----

-- SELECT LEFT(FILE_NAME,8), count(LEFT(FILE_NAME,8))
-- FROM GTSTAGE.dbo.GT_Processed_Hostgator_Mexico_dLocal_Settlement 
-- where ROW_TYPE='TX'
-- group by LEFT(FILE_NAME,8)
-- order by LEFT(FILE_NAME,8) desc

-- select top 10 * from GTSTAGE.dbo.GT_Processed_Hostgator_Mexico_dLocal_Settlement
