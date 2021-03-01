

IF OBJECT_ID('TEMPDB.DBO.#temp1', 'U') IS NOT NULL DROP TABLE #temp1;
IF OBJECT_ID('TEMPDB.DBO.#temp2', 'U') IS NOT NULL DROP TABLE #temp2;

 -- Creates matrix of all max report dates

DECLARE @start_date DATE
SET @start_date = '2020-12-01';

with 
	je_run_history as 
			(select
				brand_table
				,max(date_run) as [Latest JE Run Date]
			from gtstage.dbo.je_run_history
			group by brand_table)
	, gt as (select 
				'GT_PROCESSED_CTCT' as Brand_table  
				, '69100' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.gt_processed_ctct
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_CTCT) + '%') x
		union
			select
				'GT_PROCESSED_SITE5' AS Brand_table
				, '48500' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_PROCESSED_Site5 where reportdate > @start_date
				and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_PROCESSED_Site5) + '%') x
		union
			select 
				'GT_PROCESSED_GATOR' as Brand_table  
				, '176100' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_GATOR
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_Gator) + '%') x
		union
			select 
				'GT_PROCESSED_WHMCS' as Brand_table  
				, '48500' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_ASO
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_ASO) + '%') x			
		union
			select 
				'GT_PROCESSED_Webzai' as Brand_table  
				, '176100' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_Webzai
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_Webzai) + '%') x									
		union
			select 
				'GT_PROCESSED_JDI' as Brand_table  
				, '153400' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_JDI
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_JDI) + '%') x									
		union
			select 
				'GT_PROCESSED_HOMESTEAD' as Brand_table  
				, '48500' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_Homestead
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyyMMdd') from GTStage.dbo.GT_processed_Homestead) + '%') x
		union
			select 
				'GT_PROCESSED_Arvixe' as Brand_table  
				, '83700' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_Arvixe
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_processed_Arvixe) + '%') x
		union
			select 
				'GT_PROCESSED_CPANEL' as Brand_table  
				, '60700' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_cPanel
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyyMMdd') from GTStage.dbo.GT_Processed_cPanel) + '%') x
		union
			select 
				'GT_PROCESSED_HOSTGATOR' as Brand_table  
				, '48500' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_hostgator
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_hostgator) + '%') x
		union
			select 
				'GT_PROCESSED_VDECK' as Brand_table  
				, '48500' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_vDeck
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyyMMdd') from GTStage.dbo.GT_Processed_vDeck) + '%') x
		union
			select 
				'GT_PROCESSED_BUILDERCTCT' as Brand_table  
				, '69100' as MID
				, count(*) as [Count of GT Txns]
				, cast(max(ReportDate) as Date) as [Latest GT Report Date]
			from
				(select * from GTStage.dbo.GT_Processed_BUILDERCTCT
				where reportdate > @start_date
					and file_name like '%' + (select format(max(reportdate), 'yyyy-MM-dd') from GTStage.dbo.GT_Processed_BUILDERCTCT) + '%') x
		)
select gt.*, je_run_history.[Latest JE Run Date]
into #temp1
from gt			
JOIN je_run_history on gt.Brand_table = je_run_history.BRAND_TABLE 			
order by je_run_history.[Latest JE Run Date] asc

-- Creates a report of max report dates for all three types of merchant reports

SELECT 	CASE 
		WHEN Mid = '153400' THEN 'JDI'
		WHEN Mid = '173300' THEN 'Directi'
		WHEN Mid = '176100' THEN 'Webzai/Gator' 
		WHEN Mid = '48500' THEN 'vDeck/HS/SEOH/ASO/HG/MOJO/Site5/Host9'
		WHEN Mid = '60100' THEN 'Fast Domain' 
		WHEN Mid = '60600' THEN 'HostMonster'
		WHEN Mid = '60700' THEN 'BlueHost' 
		WHEN Mid = '69100' THEN 'CTCT/CTCT Builder' 
		WHEN Mid = '71900' THEN 'JustHost'
		WHEN Mid = '83700' THEN 'Arvixe'
	END AS Brand
	, *
INTO #temp2
FROM  (SELECT 
			Mid, 
			ReportType, 
			CAST(MAX(ActivityDate) AS DATE) AS ActivityDate 
		FROM (SELECT 
				Activity_Date AS ActivityDate, 
				'Transaction Activity' AS ReportType,
					CASE 
						WHEN file_name LIKE ('%153400%') THEN '153400'
						WHEN file_name LIKE ('%173300%') THEN '173300'
						WHEN file_name LIKE ('%176100%') THEN '176100' 
						WHEN file_name LIKE ('%48500%') THEN '48500'
						WHEN file_name LIKE ('%60100%') THEN '60100' 
						WHEN file_name LIKE ('%60600%') THEN '60600'
						WHEN file_name LIKE ('%60700%') THEN '60700' 
						WHEN file_name LIKE ('%69100%') THEN '69100' 
						WHEN file_name LIKE ('%71900%') THEN '71900'
						WHEN file_name LIKE ('%83700%') THEN '83700'
					END AS Mid 
				FROM GTSTAGE.DBO.GT_Processed_Financial_Detail_NssByTxnByActivityDate0ConveyedNegativeRefund
				WHERE  
					 file_name LIKE ('%153400%') OR 
					 file_name LIKE ('%173300%') OR 
					 file_name LIKE ('%176100%') OR 
					 file_name LIKE ('%48500%') OR 
					 file_name LIKE ('%60100%') OR 
					 file_name LIKE ('%60600%') OR 
					 file_name LIKE ('%60700%') OR 
					 file_name LIKE ('%69100%') OR 
					 file_name LIKE ('%71900%') OR 
					 file_name LIKE ('%83700%')) x
		GROUP BY Mid, ReportType

UNION 

SELECT Mid, ReportType, CAST(MAX(ActivityDate) AS DATE) AS ActivityDate 
FROM
(
	SELECT 
		Activity_Date AS ActivityDate, 
		'Activity Summary' AS ReportType,
		CASE 
			WHEN file_name LIKE ('%153400%') THEN '153400'
			WHEN file_name LIKE ('%173300%') THEN '173300'
			WHEN file_name LIKE ('%176100%') THEN '176100' 
			WHEN file_name LIKE ('%48500%') THEN '48500'
			WHEN file_name LIKE ('%60100%') THEN '60100' 
			WHEN file_name LIKE ('%60600%') THEN '60600'
			WHEN file_name LIKE ('%60700%') THEN '60700' 
			WHEN file_name LIKE ('%69100%') THEN '69100' 
			WHEN file_name LIKE ('%71900%') THEN '71900'
			WHEN file_name LIKE ('%83700%') THEN '83700'
		END AS Mid
	FROM GTSTAGE.DBO.GT_Processed_Financial_Summary_ActivityReport0
	WHERE  
	 file_name LIKE ('%153400%') OR 
	 file_name LIKE ('%173300%') OR 
	 file_name LIKE ('%176100%') OR  
	 file_name LIKE ('%48500%') OR 
	 file_name LIKE ('%60100%') OR 
	 file_name LIKE ('%60600%') OR 
	 file_name LIKE ('%60700%') OR 
	 file_name LIKE ('%69100%') OR 
	 file_name LIKE ('%71900%') OR 
	 file_name LIKE ('%83700%') 
) x
GROUP BY Mid, ReportType

UNION 

SELECT Mid, ReportType, CAST(MAX(ActivityDate) AS DATE) AS ActivityDate 
FROM
(
	SELECT 
		Activity_Date AS ActivityDate, 
		'Settlement Summary' AS ReportType,
		CASE 
			WHEN file_name LIKE ('%153400%') THEN '153400'
			WHEN file_name LIKE ('%173300%') THEN '173300'
			WHEN file_name LIKE ('%176100%') THEN '176100' 
			WHEN file_name LIKE ('%48500%') THEN '48500'
			WHEN file_name LIKE ('%60100%') THEN '60100' 
			WHEN file_name LIKE ('%60600%') THEN '60600'
			WHEN file_name LIKE ('%60700%') THEN '60700' 
			WHEN file_name LIKE ('%69100%') THEN '69100' 
			WHEN file_name LIKE ('%71900%') THEN '71900'
			WHEN file_name LIKE ('%83700%') THEN '83700'
		END AS Mid
	FROM GTSTAGE.DBO.GT_Processed_Financial_Summary_SettlementReport0
	WHERE  
	 file_name LIKE ('%153400%') OR 
	 file_name LIKE ('%173300%') OR 
	 file_name LIKE ('%176100%') OR 
	 file_name LIKE ('%48500%') OR 
	 file_name LIKE ('%60100%') OR 
	 file_name LIKE ('%60600%') OR 
	 file_name LIKE ('%60700%') OR 
	 file_name LIKE ('%69100%') OR 
	 file_name LIKE ('%71900%') OR 
	 file_name LIKE ('%83700%') 
) x
GROUP BY Mid, ReportType
) y
pivot (MAX(ActivityDate) for ReportType in ([Transaction Activity],[Activity Summary],[Settlement Summary])) as ActivityDate


select 
	#temp1.Brand_table as [GTStage Table]
	, #temp2.Brand as [Brands in Merchant Table]
	, #temp2.Mid as [Merchant ID]
	, #temp1.[Count of GT Txns]
	, #temp1.[Latest JE Run Date]
	, #temp1.[Latest GT Report Date]
	, #temp2.[Transaction Activity]
	, #temp2.[Activity Summary]
	, #temp2.[Settlement Summary]
from #temp1
join #temp2 on #temp1.MID = #temp2.MID
order by #temp1.[Latest JE Run Date] asc
