-- Create 'gt_processed_hg_Brazil_new' table on gtstage_matt

DROP TABLE GTStage_Matt.dbo.GT_Processed_HG_Brazil_New

SELECT * INTO GT_PROCESSED_HG_Brazil_NEW
FROM GTStage.dbo.GT_Processed_HG_Brazil_New
WHERE Date between '2020-06-20' and '2020-09-05'


EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.SALES_AMOUNT_USD_CALC', 'REVENUE_AMOUNT_USD_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.SALES_AMOUNT_LOCAL_CALC', 'REVENUE_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.TRANS_AMT_USD_CALC', 'TRANS_AMOUNT_USD_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.TRANS_AMT_LOCAL_CALC', 'TRANS_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.VAT_AMOUNT_LOCAL_CALC', 'TAX_AMOUNT_LOCAL_CALC', 'column'
EXECUTE sp_rename 'GTStage_Matt.dbo.GT_Processed_HG_Brazil_New.VAT_AMOUNT_USD_CALC', 'TAX_AMOUNT_USD_CALC', 'column'

-- Run 'HGBR_cash_full' script on 'gt_processed_HGBR' table


select top 1000 * from GTStage_Matt.dbo.GT_PROCESSED_HG_Brazil_NEW
--start testing code from 'HGBR_dlocal_sales' SPROC

select currency, * from GT_PROCESSED_HG_Brazil_NEW
select * from HGBR_gt

select * from  gtstage.dbo.GT_Processed_ExchangeRate
where BaseCurrencyCode = 'clp'
order by DateConversion desc


SELECT COUNT(*) GT FROM HGBR_GT
SELECT COUNT(*) DLOCAL FROM HGBR_DLOCAL
SELECT COUNT(*) ZOTHER_DIFF FROM HGBR_DLOCAL_EXCEPTION_REPORT
SELECT COUNT(*) [GT + DLOCAL] FROM HGBR_GT_DLOCAL_FULLOUTERJOIN
SELECT * FROM HGBR_GT_DLOCAL_FULLOUTERJOIN
SELECT SUM(ZOTHER_DIFF) FROM HGBR_DLOCAL_EXCEPTION_REPORT WHERE ZOTHER_DIFF <> 0
SELECT SUM(ZOTHER_DIFF) FROM HGBR_GT_DLOCAL_FULLOUTERJOIN WHERE ZDIFF_USD != 0

SELECT Invoice_ID, * FROM HGBR_GT

select top 100 * from GT_PROCESSED_HG_Brazil_NEW

select
	brand, type_calc, sum(total_invoice)
from HGBR_gt_all
group by brand, type_calc

