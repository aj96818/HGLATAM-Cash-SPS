-- Create 'gt_processed_hg_mexico_new' table on gtstage_matt

DROP TABLE GTStage_Matt.dbo.GT_Processed_HG_Mexico_New

SELECT * INTO GT_PROCESSED_HG_MEXICO_NEW
FROM GTStage.dbo.GT_Processed_HG_Mexico_New
WHERE Date > '2020-05-01'


EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.SALES_AMOUNT_USD_CALC', 'REVENUE_AMOUNT_USD_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.SALES_AMOUNT_LOCAL_CALC', 'REVENUE_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.TRANS_AMT_USD_CALC', 'TRANS_AMOUNT_USD_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.TRANS_AMT_LOCAL_CALC', 'TRANS_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.VAT_AMOUNT_LOCAL_CALC', 'TAX_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Mexico_New.VAT_AMOUNT_USD_CALC', 'TAX_AMOUNT_USD_CALC', 'column'

-- Run 'hgmx_cash_full' script on 'gt_processed_hgmx' table


select top 1000 * from GTStage_Matt.dbo.GT_PROCESSED_HG_MEXICO_NEW
--start testing code from 'hgmx_dlocal_sales' SPROC

select currency, * from GT_PROCESSED_HG_MEXICO_NEW
select * from hgmx_gt

select * from  gtstage.dbo.GT_Processed_ExchangeRate
where BaseCurrencyCode = 'clp'
order by DateConversion desc


SELECT COUNT(*) GT FROM HGMX_GT
SELECT COUNT(*) DLOCAL FROM HGMX_DLOCAL
SELECT COUNT(*) ZOTHER_DIFF FROM HGMX_DLOCAL_EXCEPTION_REPORT
SELECT COUNT(*) [GT + DLOCAL] FROM HGMX_GT_DLOCAL_FULLOUTERJOIN
SELECT * FROM HGMX_GT_DLOCAL_FULLOUTERJOIN
SELECT SUM(ZOTHER_DIFF) FROM HGMX_DLOCAL_EXCEPTION_REPORT WHERE ZOTHER_DIFF <> 0
SELECT SUM(ZOTHER_DIFF) FROM HGMX_GT_DLOCAL_FULLOUTERJOIN WHERE ZDIFF_USD != 0

SELECT Invoice_ID, * FROM HGMX_GT

select top 100 * from GT_PROCESSED_HG_MEXICO_NEW

select
	brand, type_calc, sum(total_invoice)
from hgmx_gt_all
group by brand, type_calc
