USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_EXCEPT_TEST_LOOP]    Script Date: 3/4/2021 2:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   procedure [dbo].[HGMX_EXCEPT_TEST_LOOP] as

DECLARE @PROC_DATE DATETIME
DECLARE @FINISH_DATE DATETIME
DECLARE @vGT_DATE VARCHAR(50);

--SET @PROC_DATE = '20210212'
--SET @FINISH_DATE = '20210228'
SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')

--DROP TABLE HGMX_GT_ALL
--DROP TABLE HGMX_DLOCAL_SALES_JE_ALL
--DROP TABLE HGMX_PAYPAL_SALES_JE_ALL
--DROP TABLE HGMX_DLOCAL_EXCEPTION_REPORT_ALL
--DROP TABLE HGMX_Paypal_Exception_Report_ALL
--DROP TABLE HGMX_PAYU_Exception_Report_ALL
--DROP TABLE HGMX_GT_DLOCAL_FullJoin_All
--DROP TABLE HGMX_PAYU_SALES_JE_ALL
--DROP TABLE HGMX_Overpayment_JE_ALL
--DROP TABLE HGMX_DLOCAL_CASH_JE_ALL

--SELECT * FROM HGMX_GT
--CREATE TABLE HGMX_GT_ALL (Brand VARCHAR(75), ClientID VARCHAR(55), Processor VARCHAR(25), Unique_Trans_ID VARCHAR(155), Bill_Group VARCHAR(25), Bill_Type VARCHAR(25), Date DATE, Time Time, Term VARCHAR(25), Term_Start_Date Date, Amount DECIMAL(15,2), Currency VARCHAR(20), Taxes DECIMAL(15,2), Payment_Amount DECIMAL(15,2), Payment_Currency VARCHAR(20), Offer_ID VARCHAR(125), Offer_Name VARCHAR(225), Grouping VARCHAR(55), Rebill_or_New VARCHAR(50), Country VARCHAR(20), Document VARCHAR(88), Transaction_Type VARCHAR(55), Invoice_ID VARCHAR(55), Invoice_Item_ID VARCHAR(55), Quantity VARCHAR(55), Product_Id VARCHAR(25), Full_Item_Description VARCHAR(255), Product_Date_Register Date, Product_Lifetime DECIMAL(10,2), Service_Period VARCHAR(200), PromoCode VARCHAR(155), PromoCode_Type VARCHAR(145), PromoCode_Value VARCHAR(55), Late_Fee VARCHAR(55), VAT_Tax VARCHAR(55), Net_Value DECIMAL(15,2), Net_Value_After_Taxes DECIMAL(15,2), Total_Credit_Applied VARCHAR(55), Total_Invoice DECIMAL(15,2), Total_Transaction DECIMAL(15,2), Merchant_Rates VARCHAR(55), Current_Invoice_Status VARCHAR(45), Current_Product_Status VARCHAR(50), Invoice_Date_Paid Date, TRANS_AMOUNT_USD_CALC DECIMAL(15,2), TRANS_AMOUNT_LOCAL_CALC DECIMAL(15,2), TAX_AMOUNT_LOCAL_CALC DECIMAL(15,2), TAX_AMOUNT_USD_CALC DECIMAL(15,2), REVENUE_AMOUNT_LOCAL_CALC DECIMAL(15,2), REVENUE_AMOUNT_USD_CALC DECIMAL(15,2), Business_Line_CALC VARCHAR(55), Type_CALC VARCHAR(25), SettledBy_CALC VARCHAR(50), DLOCAL_TXN_ID VARCHAR(75), Overpayment_Flag VARCHAR(5), Prepaid_Deposit_Flag VARCHAR(5), CASH_INCL_CALC INT, GAAP_INCL_CALC INT)
--CREATE TABLE HGMX_DLOCAL_SALES_JE_ALL (CHECKBOOKID VARCHAR(30), BATCHID VARCHAR(50), TRANTYPE VARCHAR(5),TRANDATE VARCHAR(50), SRCDOC VARCHAR(15), CURRID VARCHAR(25), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75), DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), DISTREF VARCHAR(255), KEY1 VARCHAR(5), REVERSEDATE VARCHAR(10), UNIQUEID VARCHAR(50), DOCAMT DECIMAL(15,2), DISTYPE INT)
--CREATE TABLE HGMX_PAYPAL_SALES_JE_ALL (CHECKBOOKID VARCHAR(75), BATCHID VARCHAR(50), TRANTYPE VARCHAR(5), TRANDATE VARCHAR(50), SRCDOC VARCHAR(15), CURRID VARCHAR(20), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75), DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), DISTREF VARCHAR(255), KEY1 VARCHAR(10),REVERSEDATE VARCHAR(20), UNIQUEID VARCHAR(50), DOCAMT DECIMAL(14,2), CASHRCPT VARCHAR(55), DISTYPE VARCHAR(25))
--CREATE TABLE HGMX_PAYU_SALES_JE_ALL (CHECKBOOKID VARCHAR(75), BATCHID VARCHAR(50), TRANTYPE VARCHAR(20), TRANDATE VARCHAR(50), SRCDOC VARCHAR(15), CURRID VARCHAR(12), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75), DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), DISTREF VARCHAR(255), KEY1 VARCHAR(10), REVERSEDATE VARCHAR(20),UNIQUEID VARCHAR(50), CASHRCPT VARCHAR(55), DISTYPE VARCHAR(25), DOCAMT DECIMAL(14,2))
--CREATE TABLE HGMX_Overpayment_JE_ALL (CHECKBOOKID VARCHAR(75), BATCHID VARCHAR(50), TRANTYPE VARCHAR(25), TRANDATE VARCHAR(50), SRCDOC VARCHAR(16), CURRID VARCHAR(15), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75), DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), DISTREF VARCHAR(255), KEY1 VARCHAR(5), REVERSEDATE VARCHAR(20), UNIQUEID VARCHAR(50), DOCAMT DECIMAL(14,2), DISTYPE VARCHAR(25))
--CREATE TABLE HGMX_DLOCAL_CASH_JE_ALL (CHECKBOOKID VARCHAR(75), BATCHID VARCHAR(50), TRANTYPE VARCHAR(15), TRANDATE VARCHAR(50), SRCDOC VARCHAR(10), CURRID VARCHAR(5), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75),  DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), DISTREF VARCHAR(255), KEY1 VARCHAR(5), REVERSEDATE VARCHAR(15), UNIQUEID VARCHAR(50), DOCAMT DECIMAL(15,2), CASHRCPT VARCHAR(55), DISTYPE VARCHAR(25))
--CREATE TABLE HGMX_DLOCAL_EXCEPTION_REPORT_ALL (invoice_id VARCHAR(75), SettledBy_CALC VARCHAR(75), Currency VARCHAR(20), COMPANY_CALC_GT VARCHAR(25), zVIND_GT VARCHAR(25), TRANS_AMOUNT_USD_CALC DECIMAL(15,2), TRANS_AMOUNT_LOCAL_CALC DECIMAL(15,2), REVENUE_Amount_USD_CALC DECIMAL(15,2), REVENUE_Amount_LOCAL_CALC DECIMAL(15,2), GT_DATE DATE, TRANSACTION_ID VARCHAR(55), COMPANY_CALC VARCHAR(25), PROCESSING_CURRENCY VARCHAR(15), PROCESSING_AMOUNT DECIMAL(15,2), NET_SETTLEMENT_AMOUNT DECIMAL(15,2), GROSS_SETTLEMENT_AMOUNT DECIMAL(15,2), DL_PROCESSING_DATE DATE, ZDIFF_USD DECIMAL(15,2), ZDIFF_ABS DECIMAL(15,2), ZOTHER_DIFF DECIMAL(15,2), zFX_Diff DECIMAL(15,2), EXCEPTION_NUM INT, EXCEPTION_ID VARCHAR(200), ALL_COMPANY VARCHAR(25))
--CREATE TABLE HGMX_PAYPAL_EXCEPTION_REPORT_ALL (COMPANY_CALC VARCHAR(25), Unique_Trans_ID VARCHAR(75), GT_Currency VARCHAR(15), GT_TRANS_AMT_USD_CALC DECIMAL(15,2), GT_TRANS_AMT_LOCAL_CALC DECIMAL(15,2), GT_Date DATE, PP_Property_CALC VARCHAR(25), PP_TxnID_CALC VARCHAR(75), PP_Gross_Amt_Currency VARCHAR(15), PP_Gross_Amt_CALC DECIMAL(15,2), PP_Fee_Amt_USD_Calc DECIMAL(15,2), Transaction_Event_Code VARCHAR(55), PP_Gross_Amt_USD_CALC DECIMAL(15,2), PP_FX_RATE_INVRS DECIMAL(12,4), PP_Exclude_CALC VARCHAR(25), PP_Activity_Date DATE, zChargeback VARCHAR(25), zCurrency_All VARCHAR(25), zCBack_Amount DECIMAL(15,2), zTrans_Amt_Diff DECIMAL(15,2), zFX_Diff DECIMAL(15,2), zOther_Diff DECIMAL(15,2), zAll_Company VARCHAR(25))
--CREATE TABLE HGMX_PAYU_EXCEPTION_REPORT_ALL (COMPANY_CALC VARCHAR(25), Unique_Trans_ID VARCHAR(255), GT_Currency VARCHAR(25), GT_TRANS_AMT_USD_CALC DECIMAL(15,2), GT_TRANS_AMT_LOCAL_CALC DECIMAL(15,2), GT_Date DATE, PAYU_Property_CALC VARCHAR(25), PAYU_TxnID_CALC VARCHAR(255), PAYU_Gross_Amt_Currency VARCHAR(25), PAYU_Gross_Amt_CALC DECIMAL(15,2), PAYU_Gross_Amt_USD_CALC DECIMAL(15,2), PAYU_FX_RATE_INVRS DECIMAL(12,4), PAYU_Activity_Date Date, zChargeback VARCHAR(25), zCurrency_All VARCHAR(25), zCBack_Amount DECIMAL(15,2), zTrans_Amt_Diff DECIMAL(15,2), zFX_Diff DECIMAL(15,2), zOther_Diff DECIMAL(15,2), zAll_Company VARCHAR(25))
--CREATE TABLE HGMX_GT_Paypal_FullJoin_ALL (COMPANY_CALC VARCHAR(25), Unique_Trans_ID VARCHAR(75), GT_Currency VARCHAR(15), GT_TRANS_AMT_USD_CALC DECIMAL(15,2), GT_TRANS_AMT_LOCAL_CALC DECIMAL(15,2), GT_Date DATE, PP_Property_CALC VARCHAR(25), PP_TxnID_CALC VARCHAR(75), PP_Gross_Amt_Currency VARCHAR(15), PP_Gross_Amt_CALC DECIMAL(15,2), PP_Fee_Amt_USD_Calc DECIMAL(15,2), Transaction_Event_Code VARCHAR(55), PP_Gross_Amt_USD_CALC DECIMAL(15,2), PP_FX_RATE_INVRS DECIMAL(12,4), PP_Exclude_CALC VARCHAR(25), PP_Activity_Date DATE)
--CREATE TABLE HGMX_GT_DLOCAL_FullJoin_ALL (invoice_id VARCHAR(75), SettledBy_CALC VARCHAR(75), Currency VARCHAR(20), COMPANY_CALC_GT VARCHAR(25), zVIND_GT VARCHAR(25), TRANS_AMOUNT_USD_CALC DECIMAL(15,2), TRANS_AMOUNT_LOCAL_CALC DECIMAL(15,2), REVENUE_Amount_USD_CALC DECIMAL(15,2), REVENUE_Amount_LOCAL_CALC DECIMAL(15,2), GT_DATE DATE, TRANSACTION_ID VARCHAR(55), COMPANY_CALC VARCHAR(25), Payment_type VARCHAR(15), PROCESSING_CURRENCY VARCHAR(15), PROCESSING_AMOUNT DECIMAL(15,2), FX_RATE DECIMAL(15,2), NET_SETTLEMENT_AMOUNT DECIMAL(15,2), GROSS_SETTLEMENT_AMOUNT DECIMAL(15,2), CREATION_DATE DATETIME, PROCESSING_DATE DATETIME, ZDIFF_USD DECIMAL(10,2), ZDIFF_ABS DECIMAL(10,2), ZOTHER_DIFF DECIMAL(10,2), ZFX_DIFF DECIMAL(10,2))
--CREATE TABLE HGMX_GT_PAYU_FULLJOIN_ALL (COMPANY_CALC VARCHAR(25), Unique_Trans_ID VARCHAR(255), GT_Currency VARCHAR(25), GT_TRANS_AMT_USD_CALC DECIMAL(15,2), GT_TRANS_AMT_LOCAL_CALC DECIMAL(15,2), GT_Date DATE, PAYU_Property_CALC VARCHAR(25), PAYU_TxnID_CALC VARCHAR(255), PAYU_Gross_Amt_Currency VARCHAR(25), PAYU_Gross_Amt_CALC DECIMAL(15,2), PAYU_Gross_Amt_USD_CALC DECIMAL(15,2), PAYU_FX_RATE_INVRS DECIMAL(12,4), PAYU_Activity_Date Date, zChargeback VARCHAR(25), zCurrency_All VARCHAR(25), zCBack_Amount DECIMAL(15,2), zTrans_Amt_Diff DECIMAL(15,2), zFX_Diff DECIMAL(15,2), zOther_Diff DECIMAL(15,2), zAll_Company VARCHAR(25))

DELETE FROM HGMX_DLOCAL_SALES_JE_ALL
DELETE FROM HGMX_GT_ALL
DELETE FROM HGMX_PAYPAL_SALES_JE_ALL
DELETE FROM HGMX_PAYU_SALES_JE_ALL
DELETE FROM HGMX_Overpayment_JE_ALL
DELETE FROM HGMX_DLOCAL_CASH_JE_ALL
DELETE FROM HGMX_DLOCAL_EXCEPTION_REPORT_ALL
DELETE FROM HGMX_PAYPAL_EXCEPTION_REPORT_ALL
DELETE FROM HGMX_PAYU_EXCEPTION_REPORT_ALL
DELETE FROM HGMX_GT_Paypal_FullJoin_ALL
--DELETE FROM HGMX_GT_DLOCAL_FullJoin_ALL
DELETE FROM HGMX_GT_PAYU_FullJoin_ALL


WHILE (@PROC_DATE <= @FINISH_DATE)
BEGIN

EXEC HGMX_DLOCAL_SALES @vGT_DATE
EXEC HGMX_PAYPAL_SALES @vGT_DATE
EXEC HGMX_PAYU_SALES @vGT_DATE
EXEC HGMX_OVERPAYMENT_SALES @vGT_DATE
EXEC HGMX_DLOCAL_CASH @vGT_DATE

-- GT Report

INSERT INTO HGMX_GT_ALL
SELECT  Brand, ClientID, Processor, Unique_Trans_ID, Bill_Group, Bill_Type, Date, Time, Term, Term_Start_Date, Amount, Currency, Taxes, Payment_Amount, Payment_Currency, Offer_ID, Offer_Name, Grouping, Rebill_or_New, Country, Document, Transaction_Type, Invoice_ID, Invoice_Item_ID, Quantity, Product_Id, Full_Item_Description, Product_Date_Register, Product_Lifetime, Service_Period, PromoCode, PromoCode_Type, PromoCode_Value, Late_Fee, VAT_Tax, Net_Value, Net_Value_After_Taxes, Total_Credit_Applied, Total_Invoice, Total_Transaction, Merchant_Rates, Current_Invoice_Status, Current_Product_Status, Invoice_Date_Paid, TRANS_AMOUNT_USD_CALC, TRANS_AMOUNT_LOCAL_CALC, TAX_AMOUNT_LOCAL_CALC, TAX_AMOUNT_USD_CALC, REVENUE_AMOUNT_LOCAL_CALC, REVENUE_AMOUNT_USD_CALC, Business_Line_CALC, Type_CALC, SettledBy_CALC, DLOCAL_TXN_ID, Overpayment_Flag, Prepaid_Deposit_Flag, CASH_INCL_CALC, GAAP_INCL_CALC
FROM HGMX_GT

-- Sales Entries

INSERT INTO HGMX_DLOCAL_SALES_JE_ALL
SELECT CHECKBOOKID,	BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE
FROM HGMX_DLOCAL_SALES_JE_FINAL

INSERT INTO HGMX_PAYPAL_SALES_JE_ALL
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, CASHRCPT, DISTYPE
FROM HGMX_PP_JE_FINAL

INSERT INTO HGMX_PAYU_SALES_JE_ALL
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, CASHRCPT, DISTYPE, DOCAMT
FROM HGMX_PAYU_JE_FINAL

INSERT INTO HGMX_OVERPAYMENT_JE_ALL
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE
FROM HGMX_OVERPAYMENT_JE

---- Cash Receipt

INSERT INTO HGMX_DLOCAL_CASH_JE_ALL
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, CASHRCPT, DISTYPE
FROM HGMX_DLOCAL_CASH_JE

---- Exception Reports

INSERT INTO HGMX_DLOCAL_EXCEPTION_REPORT_ALL
SELECT invoice_id, SettledBy_CALC, Currency, COMPANY_CALC_GT, zVIND_GT, TRANS_AMOUNT_USD_CALC, TRANS_AMOUNT_LOCAL_CALC, REVENUE_Amount_USD_CALC, REVENUE_Amount_LOCAL_CALC, GT_DATE, TRANSACTION_ID, COMPANY_CALC, PROCESSING_CURRENCY, PROCESSING_AMOUNT, NET_SETTLEMENT_AMOUNT, GROSS_SETTLEMENT_AMOUNT, DL_PROCESSING_DATE, ZDIFF_USD, ZDIFF_ABS, ZOTHER_DIFF, zFX_Diff, EXCEPTION_NUM, EXCEPTION_ID, ALL_COMPANY FROM HGMX_DLOCAL_EXCEPTION_REPORT

INSERT INTO HGMX_PAYPAL_EXCEPTION_REPORT_ALL
SELECT COMPANY_CALC, Unique_Trans_ID, GT_Currency, GT_TRANS_AMT_USD_CALC, GT_TRANS_AMT_LOCAL_CALC, GT_Date, PP_Property_CALC, PP_TxnID_CALC, PP_Gross_Amt_Currency, PP_Gross_Amt_CALC, PP_Fee_Amt_USD_Calc, Transaction_Event_Code, PP_Gross_Amt_USD_CALC, PP_FX_RATE_INVRS, PP_Exclude_CALC, PP_Activity_Date, zChargeback, zCurrency_All, zCBack_Amount, zTrans_Amt_Diff, zFX_Diff, zOther_Diff, zAll_Company FROM HGMX_Paypal_Exception_Report

INSERT INTO HGMX_PAYU_EXCEPTION_REPORT_ALL
SELECT COMPANY_CALC, Unique_Trans_ID, GT_Currency, GT_TRANS_AMT_USD_CALC, GT_TRANS_AMT_LOCAL_CALC, GT_Date, PAYU_Property_CALC, PAYU_TxnID_CALC, PAYU_Gross_Amt_Currency, PAYU_Gross_Amt_CALC, PAYU_Gross_Amt_USD_CALC, PAYU_FX_RATE_INVRS, PAYU_Activity_Date, zChargeback, zCurrency_All, zCBack_Amount, zTrans_Amt_Diff, zFX_Diff, zOther_Diff, zAll_Company FROM HGMX_PAYU_Exception_Report

--INSERT INTO HGMX_GT_DLOCAL_FULLJOIN_ALL
--SELECT invoice_id, SettledBy_CALC, Currency, COMPANY_CALC_GT, zVIND_GT, TRANS_AMOUNT_USD_CALC, TRANS_AMOUNT_LOCAL_CALC, REVENUE_Amount_USD_CALC, REVENUE_Amount_LOCAL_CALC, GT_DATE, TRANSACTION_ID, COMPANY_CALC, Payment_type, PROCESSING_CURRENCY, PROCESSING_AMOUNT, FX_RATE, NET_SETTLEMENT_AMOUNT, GROSS_SETTLEMENT_AMOUNT, PROCESSING_DATE, PROCESSING_DATE, ZDIFF_USD, ZDIFF_ABS, ZOTHER_DIFF, zFX_Diff FROM HGMX_GT_DLOCAL_FULLJOIN

INSERT INTO HGMX_GT_PAYPAL_FULLJOIN_ALL
SELECT COMPANY_CALC, Unique_Trans_ID, GT_Currency, GT_TRANS_AMT_USD_CALC, GT_TRANS_AMT_LOCAL_CALC, GT_Date, PP_Property_CALC, PP_TxnID_CALC, PP_Gross_Amt_Currency, PP_Gross_Amt_CALC, PP_Fee_Amt_USD_Calc, Transaction_Event_Code, PP_Gross_Amt_USD_CALC, PP_FX_RATE_INVRS, PP_Exclude_CALC, PP_Activity_Date FROM HGMX_GT_PAYPAL_FULLJOIN

INSERT INTO HGMX_GT_PAYU_FULLJOIN_ALL
SELECT COMPANY_CALC, Unique_Trans_ID, GT_Currency, GT_TRANS_AMT_USD_CALC, GT_TRANS_AMT_LOCAL_CALC, GT_Date, PAYU_Property_CALC, PAYU_TxnID_CALC, PAYU_Gross_Amt_Currency, PAYU_Gross_Amt_CALC, PAYU_Gross_Amt_USD_CALC, PAYU_FX_RATE_INVRS, PAYU_Activity_Date, zChargeback, zCurrency_All, zCBack_Amount, zTrans_Amt_Diff, zFX_Diff, zOther_Diff, zAll_Company FROM HGMX_GT_PAYU_FULLJOIN

SET @PROC_DATE = @PROC_DATE + 1
SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')

END

/*

select * from hgmx_gt_all order by date desc
select processor, sum(revenue_amount_usd_calc) from hgmx_gt_all where Unique_Trans_ID like '%credit%'
group by processor

Total Suspense for all days run by Merchant

SELECT 'Dlocal' as Merchant, SUM(DEBIT - CREDIT) SUSPENSE FROM HGMX_DLOCAL_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%'
UNION
SELECT 'Paypal' as Merchant, SUM(DEBIT - CREDIT) SUSPENSE FROM HGMX_PAYPAL_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%'
UNION
SELECT 'PayU' as Merchant, SUM(DEBIT - CREDIT) SUSPENSE FROM HGMX_PAYU_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%'

Total suspense by merchant and day.

WITH dlocal AS (SELECT TRANDATE, SUM(credit - debit) Suspense from HGMX_DLOCAL_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%' GROUP BY TRANDATE)
	, paypal AS (SELECT TRANDATE, SUM(credit - debit) Suspense from HGMX_PAYPAL_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%' GROUP BY TRANDATE)
	, payu AS (SELECT TRANDATE, SUM(credit - debit) Suspense from HGMX_PAYU_SALES_JE_ALL WHERE ACCOUNT LIKE '%11045%' GROUP BY TRANDATE)
SELECT 
	dlocal.trandate as TRANDATE
	, ISNULL(dlocal.Suspense, 0) as [DLOCAL Suspense]
	, ISNULL(paypal.Suspense, 0) as [Paypal Suspense]
	, ISNULL(payu.Suspense, 0) as [PayU Suspense]
FROM
	dlocal
LEFT JOIN paypal on dlocal.TRANDATE = paypal.TRANDATE
LEFT JOIN payu on dlocal.TRANDATE = payu.TRANDATE
ORDER BY Dlocal.TRANDATE asc


Total Revenue by Merchant for all days run.

SELECT 'Dlocal' as Merchant, SUM(credit - debit) Revenue from HGMX_DLOCAL_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'
UNION
SELECT 'Paypal' as Merchant, SUM(credit - debit) Revenue from HGMX_PAYPAL_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'
UNION
SELECT 'PayU' as Merchant, SUM(credit - debit) Revenue from HGMX_PAYU_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'



Combined Entries

SELECT * FROM HGMX_GT_ALL
SELECT * FROM HGMX_PAYPAL_SALES_JE_ALL
SELECT * FROM HGMX_PAYU_SALES_JE_ALL
SELECT * FROM HGMX_OVERPAYMENT_JE_ALL
SELECT * FROM HGMX_DLOCAL_SALES_JE_ALL
SELECT * FROM HGMX_DLOCAL_CASH_JE_ALL

SELECT * FROM HGMX_DLOCAL_SALES_JE_ALL
UNION
SELECT CHECKBOOKID, BATCHID, TRANDATE, REFERENCE, ACCOUNT, DISTREF, DEBIT, CREDIT, UNIQUEID, DISTYPE, DOCAMT FROM HGMX_PAYPAL_SALES_JE_ALL
UNION
SELECT CHECKBOOKID, BATCHID, TRANDATE, REFERENCE, ACCOUNT, DISTREF, DEBIT, CREDIT, UNIQUEID, DISTYPE, DOCAMT FROM HGMX_PAYU_SALES_JE_ALL

SELECT (sum(debit)-sum(credit)) diff FROM HGMX_DLOCAL_SALES_JE_ALL
UNION
SELECT (sum(debit)-sum(credit)) diff FROM HGMX_PAYPAL_SALES_JE_ALL
UNION
SELECT (sum(debit)-sum(credit)) diff FROM HGMX_PAYU_SALES_JE_ALL


Revenue entries only:

SELECT * FROM HGMX_DLOCAL_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'
UNION
SELECT CHECKBOOKID, BATCHID, TRANDATE, REFERENCE, ACCOUNT, DISTREF, DEBIT, CREDIT, UNIQUEID, DISTYPE, DOCAMT FROM HGMX_PAYPAL_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'
UNION
SELECT CHECKBOOKID, BATCHID, TRANDATE, REFERENCE, ACCOUNT, DISTREF, DEBIT, CREDIT, UNIQUEID, DISTYPE, DOCAMT FROM HGMX_PAYU_SALES_JE_ALL WHERE SUBSTRING(account, 5, 1) LIKE '%4%'




-- Unbalanced Entries DLOCAL:


SELECT
TRANDATE, SUM(DEBIT) DEBIT, SUM(CREDIT) CREDIT, (SUM(DEBIT) - SUM(CREDIT)) DIFFERENCE
FROM HGMX_DLOCAL_SALES_JE_ALL
GROUP BY TRANDATE
ORDER BY (SUM(DEBIT) - SUM(CREDIT)) DESC


SELECT COUNT(*), TYPE_CALC, BUSINESS_LINE_CALC
FROM GT_Processed_HG_Mexico_New
WHERE DATE = '2020-10-19'
GROUP BY TYPE_CALC, BUSINESS_LINE_CALC


-- Exception Reports:

select * from HGMX_DLOCAL_EXCEPTION_REPORT_all
SELECT * FROM HGMX_Paypal_Exception_Report_ALL
select * from HGMX_PAYU_Exception_Report_all

SELECT * FROM HGMX_GT_DLOCAL_FULLJOIN_ALL
SELECT * FROM HGMX_GT_PAYPAL_FULLJOIN_ALL
SELECT * FROM HGMX_GT_PAYU_FULLJOIN_ALL


select * from GTStage.dbo.GT_Processed_dLocal_all_transactions where transaction_id in ('385949', '386672', '385903', '385919', '385948', '386731')
and status = 'cleared'

select * from GTStage.dbo.gt_processed_hg_mexico_new where invoice_id in ('385949', '386672', '385903', '385919', '385948', '386731')



----------------		TOTAL MATCHED & UN-MATCHED TXNS BETWEEN GT & MERCHANT		--------------------------------

	HGMX GT <--> PAYPAL MATCHED & UNMATCHED TXNS

with gt as (
select 
	isnull(gt_date, pp_activity_date) as gt_Date 
	,count(isnull(unique_trans_id, 'gt_null')) as GT_NULL_Count 
	--, sum(zother_diff) as GT_zother_diff
	--, 'GT' as [Source]
from hgmx_gt_paypal_fulljoin_all
where unique_trans_id is null
group by isnull(gt_date, pp_activity_date)
),
pp as (
select 
	isnull(pp_activity_date, gt_date) as pp_Date 
	,count(isnull(pp_txnid_calc, 'pp_null')) as PP_NULL_Count 
	--, sum(zother_diff) as PP_zother_diff
	--, 'GT' as [Source]
from hgmx_gt_paypal_fulljoin_all
where pp_txnid_calc is null
group by ISNULL(pp_activity_date, gt_date)
),
both as (
select
	isnull(gt_date, pp_activity_date) as both_Date
	, count(*) as Total_Count
--	, sum(zother_diff) as Both_zother_diff
from hgmx_gt_paypal_fulljoin_all
group by isnull(gt_date, pp_activity_date)
)

select both.both_Date as Date, gt.GT_NULL_Count, pp.PP_NULL_Count, both.Total_Count
from both
full join gt on both.both_Date = gt.gt_Date
full join pp on both.both_Date = pp.pp_Date
order by both.both_Date 

SELECT * FROM HGMX_GT_DLOCAL_FULLJOIN_ALL


	HGMX GT <--> DLOCAL MATCHED & UNMATCHED TXNS
with gt as (
select 
	isnull(gt_date, creation_date) as gt_Date 
	,count(isnull(invoice_id, 'gt_null')) as GT_NULL_Count 
	, sum(zother_diff) as GT_zother_diff
	, 'GT' as [Source]
from hgmx_gt_dlocal_fulljoin_all
where invoice_id is null
group by isnull(gt_date, creation_date)
),
dlocal as (
select 
	isnull(creation_date, gt_date) as CREATION_DATE
	,count(isnull(transaction_id, 'dlocal_null')) as DLOCAL_NULL_Count 
	, sum(zother_diff) as DLOCAL_zother_diff
	, 'GT' as [Source]
from hgmx_gt_DLOCAL_fulljoin_all
where TRANSACTION_ID is null
group by ISNULL(CREATION_date, gt_date)
),
total as (
select
	isnull(gt_date, CREATION_date) as total_Date
	, count(*) as Total_Count
	, sum(zother_diff) as Both_zother_diff
from hgmx_gt_DLOCAL_fulljoin_all
group by isnull(gt_date, CREATION_date)
),
both as (
select
	gt_date as both_date
	, count(*) as both_count
from HGMX_GT_DLOCAL_FullJoin_ALL
where invoice_id is not null and TRANSACTION_ID is not null
group by GT_DATE
),
unmatched as (
select
	isnull(gt_date, creation_date) as unmatched_date
	, count(*) as unmatched_count
from HGMX_GT_DLOCAL_FullJoin_ALL
where invoice_id is null or TRANSACTION_ID is null
group by isnull(gt_date, creation_date) 
)

select
	total.total_Date as Date
	, gt.GT_NULL_Count as [Not in GT]
	, DLOCAL.DLOCAL_NULL_Count [Not in DLOCAL]
	, unmatched.unmatched_count as [Total Un-matched Txns]
	, both.both_count as [Total Matched Txns]
	, total.Total_Count [Total Txns]
	, ((cast(gt.gt_null_count as int) + cast(dlocal.dlocal_null_count as int)) / cast(total.Total_Count as int)) AS [% of Total Txns Un-matched]
from total
full join gt on total.Total_Date = gt.gt_Date
full join DLOCAL on total.Total_Date = DLOCAL.CREATION_Date
full join both on total.total_Date = both.both_date
full join unmatched on total.total_Date = unmatched.unmatched_date
order by total.Total_Date 

*/
