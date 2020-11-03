USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_CASH_FULL]    Script Date: 11/3/2020 2:12:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[HGMX_CASH_FULL] AS

ALTER TABLE GT_Processed_HG_Mexico_New
 ADD  FX_RATE_INVRS DECIMAL(15,8) 
 	 , TAX_TYPE_CALC VARCHAR(25)
	 , COMPANY_CALC VARCHAR(25)
     , TRANSACTION_ID_CALC VARCHAR(25)
	 , BUSINESS_LINE_CALC VARCHAR(55)
	 , TYPE_CALC VARCHAR(25)
	 , SETTLEDBY_CALC VARCHAR(55)

	--, REVENUE_AMOUNT_LOCAL_CALC DECIMAL(15,3)
	--, REVENUE_AMOUNT_USD_CALC DECIMAL(15,3)
	--, TRANS_AMOUNT_LOCAL_CALC DECIMAL(15,3)
	--, TRANS_AMOUNT_USD_CALC DECIMAL(15,3)
	--, TAX_AMOUNT_LOCAL_CALC DECIMAL(15,3)
	--, TAX_AMOUNT_USD_CALC DECIMAL(15,3)
	

--FX_RATE_INVRS
UPDATE A
SET A.FX_RATE_INVRS = ISNULL(B.INVRSRATE_CALC,1)
FROM GT_Processed_HG_Mexico_New A 
LEFT JOIN GTStage.dbo.GT_PROCESSED_EXCHANGERATE B ON B.BASECURRENCYCODE = A.CURRENCY
AND CAST(A.DATE AS DATE) = B.DATECONVERSION
 

--TYPE_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TYPE_CALC = (CASE
					WHEN (Transaction_Type = 'chargeback') THEN 'REFUND'
					WHEN Rebill_or_New = 'New' THEN 'NEW' 
					WHEN Rebill_or_New = 'Renew' THEN 'REBILL'
						ELSE 'Rebill' END)


--BUSINESS_LINE_CALC
UPDATE GT_Processed_HG_Mexico_New
SET BUSINESS_LINE_CALC = (
		CASE 
			WHEN Grouping in ('dedicated', 'reseller', 'shared', 'vps', 'builder') THEN 'Hosting'
			WHEN grouping = 'services' THEN 'Professional Services'
			WHEN Grouping in ('other', 'addon') THEN 'Add On'
			WHEN Grouping = 'domain' THEN 'domain'
			WHEN Processor is null and Grouping is null and LEN(Unique_Trans_ID) = 17 and Unique_Trans_ID like '%[a-z]%' THEN 'Cust Deposit Deferral'
			WHEN grouping IS NULL and Processor = 'Credit' THEN 'Cust Deposit Deferral'
				ELSE 'Unknown'
		END)

--select * from GTStage_Matt.dbo.hgmx_accounts_matrix_v2
/* 
	- Questions for Kat: How are we handling builder products?  Are they Add-ons, or are some Hosting?
	- Are all 'Services' groupings "Professional Services?"  Some appear related to domains.
	- How should I handle Processor = 'Credit' txns when 'Grouping' is not null
		- When Grouping is NULL and Processor = 'credit' or 'NULL' it will be classified as a 'Prepaid Deposit'

*/


--SETTLEDBY_CALC
UPDATE GT_Processed_HG_Mexico_New
SET SETTLEDBY_CALC = (CASE WHEN Processor = 'Paypal' THEN 'Paypal'
							WHEN Processor = 'Dlocal' THEN 'Dlocal'
							WHEN Unique_Trans_ID LIKE '%MANUALTRANS%' THEN 'Dlocal'  -- 'Processor' is null in this case.
							WHEN Currency not in ('MXN') 
									AND Processor is not null
									AND Processor not in ('NULL', 'Credit') THEN 'Dlocal'
							WHEN Currency in ('MXN') 
									AND Processor is not null
									AND Processor not in ('NULL', 'Credit') THEN 'PayU'
								ELSE Processor 
						END)

-- Possible Values: 'NULL', 'Boleto', 'Credit', 'DLocal', 'PayPal', 'Payu'


--TAX_TYPE_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TAX_TYPE_CALC = (CASE WHEN Country in ('US', 'United States') THEN 'UST'
 WHEN Country in ('AU','AUS','Australia','IN','IND','India','JP','JPN','Japan','NZ','NZL','New Zealand','NO','NOR','Norway','RU','RUS','Russian Federation','CH','CHE','Switzerland','TW','TWN','Taiwan') THEN 'GST'
 ELSE 'VAT' END);


--TRANS_AMOUNT_LOCAL_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TRANS_AMOUNT_LOCAL_CALC = Net_Value

--TRANS_AMOUNT_USD_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TRANS_AMOUNT_USD_CALC = TRANS_AMOUNT_LOCAL_CALC * FX_RATE_INVRS

--REVENUE_AMOUNT_LOCAL_CALC
UPDATE GT_Processed_HG_Mexico_New
SET REVENUE_AMOUNT_LOCAL_CALC = Net_Value_After_Taxes

--REVENUE_AMOUNT_USD_CALC
UPDATE GT_Processed_HG_Mexico_New
SET REVENUE_AMOUNT_USD_CALC = REVENUE_AMOUNT_LOCAL_CALC * FX_RATE_INVRS

--TAX_AMOUNT_LOCAL_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TAX_AMOUNT_LOCAL_CALC = Taxes

--TAX_AMOUNT_USD_CALC
UPDATE GT_Processed_HG_Mexico_New
SET TAX_AMOUNT_USD_CALC = Taxes * FX_RATE_INVRS





--select top 100 * from GTStage.dbo.GT_Processed_HG_Mexico_New
--order by date desc

--select distinct Country from GTStage.dbo.GT_Processed_HG_Mexico_New

--select top 100 * FROM GTStage.dbo.GT_Processed_dLocal_all_transactions
--WHERE ROW_TYPE IN ('TX')
--	AND LEFT(file_name, 8) = @DLOCAL_DATE --Replace with "@DLOCAL_DATE" in final script
--	AND CAST(CREATION_DATE AS DATE) = CAST(@VDATE2 AS DATE)  -- Replace with "@VDATE2" in final script.
--	AND STATUS = 'cleared'
--	AND BANK_MID = '2049'




--SELECT DISTINCT TYPE_CALC FROM GTStage.dbo.GT_Processed_HG_Mexico_New 
--select top 100 * from GTStage.dbo.GT_Processed_HG_Mexico_New order by date desc



--ALTER TABLE hgmexico_temptable
--ADD
--CustDeposit_Release_Flag VARCHAR(50)
--,IN_ENGLISH VARCHAR(250)
--,zDescription VARCHAR(400)
--,zCompany VARCHAR(50)
--,Aspect VARCHAR (150)
--,FX_RATE_INVRS DECIMAL(6,6)
