USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_DLOCAL_SALES]    Script Date: 9/25/2020 9:52:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER procedure [dbo].[HGBR_BRASPAG_SALES] @vDate VARCHAR(15) AS

EXEC HGBR_DROPS


--DECLARE @vDate VARCHAR(15)
--SET @vDate = '20200702'

DECLARE @vDate_Datetime DATETIME
SET @vDate_Datetime = @vDate

DECLARE @BRASPAG_DATE VARCHAR(15)
SET @BRASPAG_DATE = FORMAT(DATEADD(dd, 1, @vDate_Datetime), 'yyyyMMdd')

DECLARE @vDate_YYYY_MM_DD VARCHAR(15)
SET @vDate_YYYY_MM_DD = FORMAT(@vDate_Datetime, 'yyyy-MM-dd')

-- All Tables:
-- 1) HGBR_GT: all GT txns for one day.
-- 2) HGBR_BRASPAG: all dlocal txns for one day.
-- 3) HGBR_Summ_Rev: Summary of the Revenue according to the GT for one day

SELECT *
INTO HGBR_GT
FROM GT_Processed_HG_Brazil_New
WHERE Date = @vDate_YYYY_MM_DD 
--	AND	SettledBy_CALC = 'DLocal'

--select top 18 * from GT_Processed_HG_Brazil_New
