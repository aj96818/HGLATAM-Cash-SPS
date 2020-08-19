USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_EXCEPT_TEST_LOOP]    Script Date: 8/19/2020 6:50:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   procedure [dbo].[HGMX_EXCEPT_TEST_LOOP] as

DECLARE @PROC_DATE DATETIME
DECLARE @FINISH_DATE DATETIME
DECLARE @vGT_DATE VARCHAR(50);

SET @PROC_DATE = '20200601'
SET @FINISH_DATE = '20200630'
SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')

--DROP TABLE HGMX_DLOCAL_SALES_JE_ALL
--DROP TABLE HGMX_GT_ALL

--CREATE TABLE HGMX_DLOCAL_SALES_JE_ALL (CHECKBOOKID VARCHAR(75), BATCHID VARCHAR(50), TRANDATE VARCHAR(50), REFERENCE VARCHAR(255), ACCOUNT VARCHAR(75), DISTREF VARCHAR(255), DEBIT DECIMAL(13,2), CREDIT DECIMAL(13,2), UNIQUEID VARCHAR(50), DOCAMT DECIMAL(14,2), table_name VARCHAR(155))
--CREATE TABLE HGMX_GT_ALL (Brand VARCHAR(75), ClientID VARCHAR(55), Processor VARCHAR(25), Unique_Trans_ID VARCHAR(155), Bill_Group VARCHAR(25), Bill_Type VARCHAR(25), Date DATE, Time Time, Term VARCHAR(25), Term_Start_Date Date, Amount DECIMAL(15,2), Currency VARCHAR(20), Taxes DECIMAL(15,2), Payment_Amount DECIMAL(15,2), Payment_Currency VARCHAR(20), Offer_ID VARCHAR(125), Offer_Name VARCHAR(225), Grouping VARCHAR(55), Rebill_or_New VARCHAR(50), Country VARCHAR(20), Document VARCHAR(88), Transaction_Type VARCHAR(55), Invoice_ID VARCHAR(55), Invoice_Item_ID VARCHAR(55), Quantity VARCHAR(55), Product_Id VARCHAR(25), Full_Item_Description VARCHAR(255), Product_Date_Register Date, Product_Lifetime DECIMAL(10,2), Service_Period VARCHAR(200), PromoCode VARCHAR(155), PromoCode_Type VARCHAR(145), PromoCode_Value VARCHAR(55), Promo_Value VARCHAR(55), Late_Fee VARCHAR(55), VAT_Tax VARCHAR(55), Net_Value DECIMAL(15,2), Local_Taxes_Amount VARCHAR(55), Net_Value_After_Taxes DECIMAL(15,2), Total_Credit_Applied VARCHAR(55), Total_Invoice DECIMAL(15,2), Total_Transaction DECIMAL(15,2), Merchant_Rates VARCHAR(55), Total_Transaction_minus_Merch_Rates DECIMAL(15,2), Current_Invoice_Status VARCHAR(45), Current_Product_Status VARCHAR(50), Invoice_Date_Paid Date, ID VARCHAR(45), file_name VARCHAR(75), TRANS_AMOUNT_USD_CALC DECIMAL(15,2), TRANS_AMOUNT_LOCAL_CALC DECIMAL(15,2), TAX_AMOUNT_LOCAL_CALC DECIMAL(15,2), TAX_AMOUNT_USD_CALC DECIMAL(15,2), REVENUE_AMOUNT_LOCAL_CALC DECIMAL(15,2), REVENUE_AMOUNT_USD_CALC DECIMAL(15,2), Business_Line_CALC VARCHAR(55), Type_CALC VARCHAR(25), SettledBy_CALC VARCHAR(50), DLOCAL_TXN_ID VARCHAR(75))

DELETE FROM HGMX_DLOCAL_SALES_JE_ALL
DELETE FROM HGMX_GT_ALL

WHILE (@PROC_DATE <= @FINISH_DATE)
BEGIN

EXEC HGMX_DLOCAL_SALES @vGT_DATE
--EXEC sp_Homestead_AMEX @vGT_DATE;

INSERT INTO HGMX_DLOCAL_SALES_JE_ALL
SELECT CHECKBOOKID, BATCHID, TRANDATE, REFERENCE, ACCOUNT, DISTREF, DEBIT, CREDIT, UNIQUEID, table_name FROM HGMX_DLOCAL_JE

INSERT INTO HGMX_GT_ALL
SELECT  Brand, ClientID, Processor, Unique_Trans_ID, Bill_Group, Bill_Type, Date, Time, Term, Term_Start_Date, Amount, Currency, Taxes, Payment_Amount, Payment_Currency, Offer_ID, Offer_Name, Grouping, Rebill_or_New, Country, Document, Transaction_Type, Invoice_ID, Invoice_Item_ID, Quantity, Product_Id, Full_Item_Description, Product_Date_Register, Product_Lifetime, Service_Period, PromoCode, PromoCode_Type, PromoCode_Value, Promo_Value, Late_Fee, VAT_Tax, Net_Value, Local_Taxes_Amount, Net_Value_After_Taxes, Total_Credit_Applied, Total_Invoice, Total_Transaction, Merchant_Rates, Total_Transaction_minus_Merch_Rates, Current_Invoice_Status, Current_Product_Status, Invoice_Date_Paid, ID, file_name, TRANS_AMOUNT_USD_CALC, TRANS_AMOUNT_LOCAL_CALC, TAX_AMOUNT_LOCAL_CALC, TAX_AMOUNT_USD_CALC, REVENUE_AMOUNT_LOCAL_CALC, REVENUE_AMOUNT_USD_CALC, Business_Line_CALC, Type_CALC, SettledBy_CALC, DLOCAL_TXN_ID
FROM HGMX_GT

SET @PROC_DATE = @PROC_DATE + 1
SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')

END

--SELECT RIGHT(TRANDATE,4) + LEFT(TRANDATE, 4) DATE, SUM(DEBIT - CREDIT) SUSPENSE
--FROM HGMX_DLOCAL_SALES_JE_ALL
--WHERE ACCOUNT LIKE '%11045%'
--GROUP BY RIGHT(TRANDATE, 4) + LEFT(TRANDATE, 4);

--SELECT * FROM HGMX_DLOCAL_SALES_JE_ALL
--SELECT * FROM HGMX_GT_ALL