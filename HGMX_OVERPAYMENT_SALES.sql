USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_OVERPAYMENT_SALES]    Script Date: 11/11/2020 12:58:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROCEDURE [dbo].[HGMX_OVERPAYMENT_SALES] @vDate VARCHAR(15) AS 

--DECLARE @vDate VARCHAR(15)
--SET @vDate = '20201029'

DECLARE @vDate_Datetime DATETIME
SET @vDate_Datetime = @vDate

SELECT *
INTO HGMX_GT_OVERPAYMENT
FROM HGMX_GT
WHERE Total_Transaction > Total_Invoice

ALTER TABLE HGMX_GT_OVERPAYMENT
ADD Overpayment DECIMAL(15,2)
, Overpayment_USD DECIMAL(15,2)


UPDATE HGMX_GT_OVERPAYMENT SET Overpayment = Total_Transaction - Total_Invoice - VAT_Tax
UPDATE HGMX_GT_OVERPAYMENT SET Overpayment_USD = (Total_Transaction - Total_Invoice - VAT_Tax) * FX_RATE_INVRS

SELECT
	COMPANY_CALC
	, Type_CALC
	, BUSINESS_LINE_CALC
--	, SETTLEDBY_CALC
	, SUM(Overpayment_USD) AS Overpayment_USD
	, @vDate AS zImport_Date
INTO HGMX_Summ_Overpayment
FROM HGMX_GT_OVERPAYMENT
WHERE SettledBy_Calc <> 'CREDIT'
AND Overpayment_USD <> 0
GROUP BY 
	COMPANY_CALC
	, Type_CALC
	, BUSINESS_LINE_CALC
--	, SETTLEDBY_CALC


ALTER TABLE HGMX_Summ_Overpayment ADD CHECKBOOKID VARCHAR(50), BATCHID VARCHAR(50), TRANTYPE VARCHAR(50), TRANDATE VARCHAR(50), SRCDOC VARCHAR(50), CURRID VARCHAR(50), REFERENCE VARCHAR(50), ACCOUNT VARCHAR(50), DEBIT DECIMAL(15, 2), CREDIT DECIMAL(15, 2), DISTREF VARCHAR(150), KEY1 VARCHAR(50), REVERSEDATE VARCHAR(50), UNIQUEID VARCHAR(50), Table_name VARCHAR(120)

UPDATE HGMX_Summ_Overpayment SET Table_Name = 'HGMX_Summ_Overpayment'
UPDATE HGMX_Summ_Overpayment SET CHECKBOOKID = 'Operating'
UPDATE HGMX_Summ_Overpayment SET ACCOUNT = ISNULL(B.Account_Num, '')
FROM HGMX_Summ_Overpayment A
LEFT JOIN GTStage_Matt.dbo.hgmx_accounts_matrix_v2 B
ON A.COMPANY_CALC = B.Company_Calc
AND A.TYPE_CALC = B.Type_Calc
AND A.Business_Line_CALC = B.Business_Line_Calc 
UPDATE HGMX_Summ_Overpayment SET BATCHID = 'ACL_' + FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_Summ_Overpayment SET TRANTYPE = 5
UPDATE HGMX_Summ_Overpayment SET TRANDATE = FORMAT(@vDate_Datetime, 'MMddyyyy')
UPDATE HGMX_Summ_Overpayment SET SRCDOC = 'ACL'
UPDATE HGMX_Summ_Overpayment SET CURRID = 'Z-US$'
UPDATE HGMX_Summ_Overpayment SET REFERENCE = FORMAT(@vDate_Datetime, 'MMddyyyy') + ' REVENUE';
UPDATE HGMX_Summ_Overpayment SET DEBIT = (CASE WHEN Overpayment_USD < 0 THEN 0 ELSE Overpayment_USD END);
UPDATE HGMX_Summ_Overpayment SET CREDIT = (CASE WHEN Overpayment_USD > 0 THEN 0 ELSE Overpayment_USD * - 1 END)
UPDATE HGMX_Summ_Overpayment SET DISTREF = COMPANY_CALC + ' ' + TYPE_CALC + ' ' + Business_Line_CALC + ' - ' + ' SALES';
UPDATE HGMX_Summ_Overpayment SET KEY1 = ''
UPDATE HGMX_Summ_Overpayment SET REVERSEDATE = ''
UPDATE HGMX_Summ_Overpayment SET UNIQUEID = 'HGMXOP' + FORMAT(@vDate_Datetime, 'MMddyyyy');

SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
INTO HGMX_Overpayment_JE
FROM HGMX_Summ_Overpayment

UPDATE HGMX_Summ_Overpayment SET ACCOUNT = ISNULL(B.Account_Num, '')
FROM HGMX_Summ_Overpayment A
LEFT JOIN GTStage_Matt.dbo.hgmx_accounts_matrix_v2 B
ON A.COMPANY_CALC = B.Company_Calc
--AND A.TYPE_CALC = B.Type_Calc
AND 'Cust Deposit Deferral' = B.Business_Line_Calc 
UPDATE HGMX_Summ_Overpayment SET Credit = (CASE WHEN Overpayment_USD < 0 THEN 0 ELSE Overpayment_USD END);
UPDATE HGMX_Summ_Overpayment SET Debit = (CASE WHEN Overpayment_USD > 0 THEN 0 ELSE Overpayment_USD * - 1 END)
UPDATE HGMX_Summ_Overpayment SET DISTREF = COMPANY_CALC + ' Prepaid Deposit';

INSERT INTO HGMX_Overpayment_JE
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, table_name
FROM HGMX_Summ_Overpayment

--SELECT * FROM HGMX_GT_OVERPAYMENT
--SELECT * FROM HGMX_Summ_Overpayment
--select * from HGMX_Overpayment_JE

--DROP TABLE HGMX_GT_OVERPAYMENT
--DROP TABLE HGMX_Summ_Overpayment
--DROP TABLE HGMX_Overpayment_JE

--select * from GTStage_Matt.dbo.hgmx_accounts_matrix_v2
