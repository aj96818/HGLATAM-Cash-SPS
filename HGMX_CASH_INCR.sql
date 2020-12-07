USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_CASH_FULL]    Script Date: 12/7/2020 8:35:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[HGMX_CASH_INCR] AS


DECLARE @LAST_DATE [DATETIME]

SET @LAST_DATE = (
		SELECT ISNULL(MAX(DWCREATETIME), DATEADD(DD, DATEDIFF(DD, 0, GETDATE()), 0))
		FROM GT_PROCESSED_HGLATAM
		WHERE FX_RATE_INVRS IS NOT NULL );


--FX_RATE_INVRS
UPDATE A
SET A.FX_RATE_INVRS = ISNULL(B.INVRSRATE_CALC,1)
FROM GT_Processed_HGLATAM A 
LEFT JOIN GTStage.dbo.GT_PROCESSED_EXCHANGERATE B ON B.BASECURRENCYCODE = A.CURRENCY
AND CAST(A.DATE AS DATE) = B.DATECONVERSION
WHERE A.DWCREATETIME >= @LAST_DATE;


--TYPE_CALC
UPDATE GT_Processed_HGLATAM
SET TYPE_CALC = (CASE
					WHEN (Transaction_Type = 'chargeback' AND Unique_Trans_ID not like '%MANUALTRANS%') THEN 'REFUND'
					WHEN (Transaction_Type = 'chargeback' AND Unique_Trans_ID like '%MANUALTRANS%') THEN 'CHARGEBACK'
					WHEN (Rebill_or_New = 'New' and Transaction_Type <> 'chargeback') THEN 'NEW' 
					WHEN (Rebill_or_New = 'Renew' and Transaction_Type <> 'chargeback') THEN 'REBILL'
						ELSE 'Rebill' END)
				WHERE DWCREATETIME >= @LAST_DATE;


--BUSINESS_LINE_CALC
UPDATE GT_Processed_HGLATAM
SET BUSINESS_LINE_CALC = (
		CASE 
			WHEN Grouping in ('dedicated', 'reseller', 'shared', 'vps', 'builder') THEN 'Hosting'
			WHEN grouping = 'services' THEN 'Professional Services'
			WHEN Grouping in ('other', 'addon') THEN 'Add On'
			WHEN Grouping = 'domain' THEN 'Domain'
			WHEN Processor is null and Grouping is null and LEN(Unique_Trans_ID) = 17 and Unique_Trans_ID like '%[a-z]%' THEN 'Cust Deposit'
			WHEN grouping IS NULL and Transaction_Type = 'payment|cash deposit' THEN 'Cust Deposit'
			WHEN grouping IS NULL and Processor = 'Credit' THEN 'Cust Deposit'
				ELSE 'Hosting'
		END)
	WHERE DWCREATETIME >= @LAST_DATE;

--select * from GT_PROCESSED_HGLATAM where Business_Line_CALC = 'unknown'
--select * from GTStage_Matt.dbo.hgmx_accounts_matrix_v2
/* 
	- Questions for Kat: How are we handling builder products?  Are they Add-ons, or are some Hosting?
	- Are all 'Services' groupings "Professional Services?"  Some appear related to domains.
	- How should I handle Processor = 'Credit' txns when 'Grouping' is not null
		- When Grouping is NULL and Processor = 'credit' or 'NULL' it will be classified as a 'Prepaid Deposit'

*/

--SETTLEDBY_CALC
UPDATE GT_Processed_HGLATAM
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
				WHERE DWCREATETIME >= @LAST_DATE;
-- Possible Values: 'NULL', 'Boleto', 'Credit', 'DLocal', 'PayPal', 'Payu'


--TAX_TYPE_CALC
UPDATE GT_Processed_HGLATAM
SET TAX_TYPE_CALC = (CASE WHEN Country in ('US', 'United States') THEN 'UST'
 WHEN Country in ('AU','AUS','Australia','IN','IND','India','JP','JPN','Japan','NZ','NZL','New Zealand','NO','NOR','Norway','RU','RUS','Russian Federation','CH','CHE','Switzerland','TW','TWN','Taiwan') THEN 'GST'
 ELSE 'VAT' END)
WHERE DWCREATETIME >= @LAST_DATE;

--TRANS_AMOUNT_LOCAL_CALC:
UPDATE GT_Processed_HGLATAM
SET TRANS_AMOUNT_LOCAL_CALC = ISNULL(Total_Transaction, 0)
WHERE DWCREATETIME >= @LAST_DATE;

--TRANS_AMOUNT_USD_CALC
UPDATE GT_Processed_HGLATAM
SET TRANS_AMOUNT_USD_CALC = TRANS_AMOUNT_LOCAL_CALC * ISNULL(FX_RATE_INVRS, 0)
WHERE DWCREATETIME >= @LAST_DATE;

--TAX_AMOUNT_LOCAL_CALC
UPDATE GT_Processed_HGLATAM
SET TAX_AMOUNT_LOCAL_CALC = ISNULL(Taxes, 0)
WHERE DWCREATETIME >= @LAST_DATE;

--REVENUE_AMOUNT_LOCAL_CALC: 
UPDATE GT_Processed_HGLATAM
SET REVENUE_AMOUNT_LOCAL_CALC = TRANS_AMOUNT_LOCAL_CALC - TAX_AMOUNT_LOCAL_CALC
WHERE DWCREATETIME >= @LAST_DATE;

--REVENUE_AMOUNT_USD_CALC
UPDATE GT_Processed_HGLATAM
SET REVENUE_AMOUNT_USD_CALC = REVENUE_AMOUNT_LOCAL_CALC * FX_RATE_INVRS
WHERE DWCREATETIME >= @LAST_DATE;

--TAX_AMOUNT_USD_CALC: Taxes = Taxes (Local) + VAT_Taxes
UPDATE GT_Processed_HGLATAM
SET TAX_AMOUNT_USD_CALC = TAX_AMOUNT_LOCAL_CALC * FX_RATE_INVRS
WHERE DWCREATETIME >= @LAST_DATE;

--CASH_INCL_CALC:
UPDATE GT_Processed_HGLATAM
SET CASH_INCL_CALC = (CASE WHEN SETTLEDBY_CALC = 'Credit' THEN 0 ELSE 1 END)
WHERE DWCREATETIME >= @LAST_DATE;

--GAAP_INCL_CALC:
UPDATE GT_Processed_HGLATAM
SET GAAP_INCL_CALC = (CASE WHEN BUSINESS_LINE_CALC = 'Cust Deposit' AND Settledby_CALC <> 'CREDIT' THEN 0 ELSE 1 END)
WHERE DWCREATETIME >= @LAST_DATE;
