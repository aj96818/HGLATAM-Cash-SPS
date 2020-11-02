USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_WRAPPER]    Script Date: 11/1/2020 10:39:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author: ERIC SOLOMON / Alan Jackson
/* Description: WRAPPER SPROC FOR HGMX CASH SPS
	This stored procedure sets the run date for the individual cash revenue SPROCs
	and runs them - halting the creation of the journal entries if exceptions are encountered
	while running any of the individual SPROCs.
	
	The individual SPROCs that this Wrapper SPROC executes are:
		HGMX_PayU_Sales
		HGMX_DLOCAL_CASH 
		HGMX_DLOCAL_SALES 
		HGMX_PAYPAL_SALES

	The conditions that stop the completion of the Wrapper SPROC are the following:
		1. If any of the Cash Receipt or Sales journal entries are unbalanced by more than
			$100, the Wrapper SPS terminates. "Unbalanced Entry" email is sent.
		2. If any of the cash receipt or sales JEs have a total suspense > $2,500, then the Wrapper SPS terminates.
		   Suspense is the difference between the txn amount in the merchant report versus the GT report.
		   "HGMX High Exceptions @vDate" email is sent.
		3. If the Wrapper fails to execute any of the individual Cash stored procedures for any reason other than the ones listed above,
			the Wrapper terminates.  "DB - HGMX PROCESSING ERROR" email is sent. */
-- =============================================

ALTER   PROCEDURE [dbo].[HGMX_WRAPPER] AS

SET NOCOUNT ON;

-- Declaring variables for e-mail subject and body to use in Exceptions e-mails.
DECLARE @vSUBJECT VARCHAR(255)
DECLARE @VBODY VARCHAR(255)
DECLARE @PROC_DATE DATETIME
Declare @filenames varchar(max)


/* This sets the run date for the Wrapper SPS to a day after the 
last day that the Wrapper SPS ran successfully given by the JE_RUN_HISTORY table */
SET @PROC_DATE = (
		SELECT DATEADD(DD, 1, MAX(DATE_RUN))
		FROM JE_RUN_HISTORY
		WHERE STOP_DATE IS NOT NULL
			AND BRAND_TABLE = 'GT_PROCESSED_HGMX'
		);

DECLARE @START_DATE DATETIME;
DECLARE @END_DATE DATETIME;

/* End date is the latest date the Wrapper can be run which is contingent upon
when we receive the Litle Activity Report. */

SET @END_DATE = (
		SELECT MAX(CAST(Update_date AS DATE))
		FROM GTStage.dbo.GT_Processed_HGLATAM_PayU
		);
		
DECLARE @vGT_DATE VARCHAR(50);

/* Beginning of the loop that runs the individual stored procedures
starting at the last successful run date and incrementing a day at a time
until 'procedure date' is less than or equal to 'end date.'  */

BEGIN TRY
	WHILE (@PROC_DATE <= @END_DATE)
	BEGIN
		SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')
		SET @START_DATE = getdate();

		DECLARE @vDEL_DATE VARCHAR(50);

		SET @vDEL_DATE = 'ACL_' + SUBSTRING(@vGT_DATE, 5, 4) + SUBSTRING(@vGT_DATE, 1, 4);

		DELETE
		FROM GTSTAGE.dbo.COMMON_JE
		WHERE BATCHID_CALC = @vDEL_DATE
			AND BRAND_CALC = 'HGMX'

		/* Calling the four stored procedures that
		 build a day's worth of Journal Entries for Rev Accounting. */

		EXEC HGMX_DLOCAL_SALES @vGT_DATE;
		EXEC HGMX_DLOCAL_CASH @vGT_DATE;
		EXEC HGMX_PayU_Sales @vGT_DATE;
		EXEC HGMX_PAYPAL_SALES @vGT_DATE;		

		--BALANCE TESTS
				/*The subsequent code blocks check to see if each final JE table is balanced or not.
				If the difference between the sum and the credits is greater than $100 than 
				the Wrapper stops here and an Unbalanced Exceptions email is sent out. */
		
-- HGMX_PAYU_SALES
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PAYU_JE_Final
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX  Unbalanced Entries "HGMX_PayU_JE_Final" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_PayU_JE_Final" ' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY;

			RETURN;
		END
		ELSE IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PAYU_JE_Final
					GROUP BY CHECKBOOKID
					)) > 0
			--RUN BALANCE ENTRY
			EXECUTE dbo.sp_balance_entry_cp_NO_CR 'HGMX_PayU_JE_Final'
				,'061-11045-000';

--HGMX_DLOCAL_Cash
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLocal_Cash_JE
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX  Unbalanced Entries "HGMX_DLocal_Cash_JE" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_DLocal_Cash_JE" ' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY;

			RETURN;
		END
		ELSE IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLocal_Cash_JE
					GROUP BY CHECKBOOKID
					)) > 0
			--RUN BALANCE ENTRY
			EXECUTE dbo.sp_balance_entry_cp_NO_CR 'HGMX_DLocal_Cash_JE'
				,'061-11045-000';

--HGMX_DLOCAL_Sales
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLOCAL_SALES_JE_FINAL
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX  Unbalanced Entries "HGMX_DLOCAL_SALES_JE_FINAL" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_DLOCAL_SALES_JE_FINAL" ' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY;

			RETURN;
		END
		ELSE IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLOCAL_SALES_JE_FINAL
					GROUP BY CHECKBOOKID
					)) > 0
			--RUN BALANCE ENTRY
			EXECUTE dbo.sp_balance_entry_cp_NO_CR 'HGMX_DLOCAL_SALES_JE_FINAL'
				,'061-11045-000';

--HGMX_PAYPAL_SALES
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PP_JE_Final
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX  Unbalanced Entries "HGMX_PP_JE_Final" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_PP_JE_Final" ' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY;

			RETURN;
		END
		ELSE IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PP_JE_Final
					GROUP BY CHECKBOOKID
					)) > 0
			--RUN BALANCE ENTRY
			EXECUTE dbo.sp_balance_entry_cp_NO_CR 'HGMX_PP_JE_Final'
				,'061-11045-000';


										
-- Next step in Wrapper: Check for X's in the respective "Account" fields for each final JE and stop the Wrapper if any are present.
		IF (SELECT COUNT(*) FROM
					(SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_PAYU_JE_Final
					UNION 
					SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_DLOCAL_SALES_JE_FINAL
					UNION
					SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_PP_JE_Final
					UNION
					SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_DLocal_Cash_JE
					) UN
				WHERE UN.ACCOUNT LIKE ('%XX%')) > 0
		BEGIN
		-- Execute block of code if X's in Account
			SET @vSUBJECT = 'DB - HGMX Xs in Account Numbers' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Xs in Account Numbers' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'acl_reporting@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY
			RETURN;
		END
		
-- EXCEPTION TESTS

IF ABS((
		SELECT (SUM(UN.DEBIT) - SUM(UN.CREDIT))
			FROM (SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_PAYU_JE_Final
				UNION
	     		SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_PP_JE_Final
				UNION
				SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_DLOCAL_SALES_JE_FINAL
				UNION
				SELECT CREDIT, DEBIT, ACCOUNT FROM HGMX_DLocal_Cash_JE
				) UN
		WHERE UN.ACCOUNT IN ('061-11045-000')
		)) > 2500

		BEGIN
			--SEND EMAIL ABOUT HIGH SUSPENSE AND STOP JOB
			SET @vSUBJECT = 'DB - HGMX High Exceptions ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX High Exceptions ' + @vGT_DATE + '. Please check tables.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'acl_reporting@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY

			RETURN;
		END


-- COMMON JE INSERTS

---- HGMX_PAYU
INSERT INTO COMMON_JE (CHECKBOOKID_CALC, BATCHID_CALC, TRANTYPE_CALC, TRANDATE_CALC, SRCDOC_CALC, CURRID_CALC, REFRENCE_CALC, ACCOUNT_CALC, DEBIT, CREDIT, DISTREF_CALC, KEY1_CALC, REVERSEDATE_CALC, UNIQUEID_CALC, DOCAMT_CALC, DISTYPE_CALC, BRAND_CALC, MERCHANT_CALC)
--,CASHRCPT_CALC
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE, 'HGMX', 'PayU'
FROM HGMX_PAYU_JE_Final;

---- HGMX_PAYPAL
INSERT INTO COMMON_JE (CHECKBOOKID_CALC, BATCHID_CALC, TRANTYPE_CALC, TRANDATE_CALC, SRCDOC_CALC, CURRID_CALC, REFRENCE_CALC, ACCOUNT_CALC, DEBIT, CREDIT, DISTREF_CALC, KEY1_CALC, REVERSEDATE_CALC, UNIQUEID_CALC, DOCAMT_CALC, DISTYPE_CALC, BRAND_CALC, MERCHANT_CALC)
--,CASHRCPT_CALC
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE, 'HGMX', 'Paypal'
FROM HGMX_PP_JE_Final

---- HGMX DLOCAL_SALES
INSERT INTO COMMON_JE (CHECKBOOKID_CALC, BATCHID_CALC, TRANTYPE_CALC, TRANDATE_CALC, SRCDOC_CALC, CURRID_CALC, REFRENCE_CALC, ACCOUNT_CALC, DEBIT, CREDIT, DISTREF_CALC, KEY1_CALC, REVERSEDATE_CALC, UNIQUEID_CALC, DOCAMT_CALC, DISTYPE_CALC, BRAND_CALC, MERCHANT_CALC)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE, 'HGMX', 'DLOCAL'
FROM HGMX_DLOCAL_SALES_JE_FINAL

---- HGMX PayU_SALES
INSERT INTO COMMON_JE (CHECKBOOKID_CALC, BATCHID_CALC, TRANTYPE_CALC, TRANDATE_CALC, SRCDOC_CALC, CURRID_CALC, REFRENCE_CALC, ACCOUNT_CALC, DEBIT, CREDIT, DISTREF_CALC, KEY1_CALC, REVERSEDATE_CALC, UNIQUEID_CALC, DOCAMT_CALC, DISTYPE_CALC, BRAND_CALC, MERCHANT_CALC)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE, 'HGMX', 'PayU'
FROM HGMX_PAYU_JE_Final


-- COMMON EXCEPTION INSERTS

		-- CREATE EXTRACTS HERE

		--EXECUTE [DMFLogging].[dbo].[sp_HGMX_JE_Feed] @vGT_DATE;

		/* If Wrapper SPS runs up to this point, insert the date
		that got run (along with some add'l details) into the 
		JE_RUN_HISTORY table so that the @PROC_DATE (procedure date)
		gets incremented by one day and continues the WHILE loop
		until @PROC_DATE <= @END_DATE */

		INSERT INTO JE_RUN_HISTORY (
			run_id
			,start_date
			,stop_Date
			,date_run
			,brand_table
			)
		SELECT max(run_id) + 1
			,@START_DATE
			,getdate()
			,@PROC_DATE
			,'GT_PROCESSED_HGMX'
		FROM JE_RUN_HISTORY

		Set @filenames = '\\corp.endurance.com\acl\axcore\Fin Ops Job Files\Entries\Sale\'+ @vGT_DATE + '_PAYU_JE_HGMX.xlsx'

		Set @filenames = (CASE WHEN (SELECT COUNT(*) FROM HGMX_PayU_Cash_JE_Final) > 0 THEN @filenames + ';\\corp.endurance.com\acl\axcore\Fin Ops Job Files\Entries\Cash_Rec\'+ @vGT_DATE + '_PayUCash_JE_HGMX.xlsx'
		ELSE @filenames END)

		Set @filenames = (CASE WHEN (SELECT COUNT(*) FROM HGMX_PayU_Exception_Report) > 0 THEN @filenames + ';\\corp.endurance.com\acl\axcore\Fin Ops Job Files\Entries\Exception_Reports\'+ @vGT_DATE + '_HGMX_PAYU_Exceptions.xlsx'
		ELSE @filenames END)
		
		SET @vSUBJECT = 'DB - HGMX Journal Entries and Exception Reports ' + @vGT_DATE;
		SET @vBODY = 'DB - Journal Entries and Exception Reports for ' + @vGT_DATE + ' are now available.';

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com'--,apac-obaccounts@endurance.com'
			,@subject = @vSUBJECT
			,@body = @vBODY
			,@file_attachments = @filenames;

		SET @PROC_DATE = DATEADD(DD, 1, @PROC_DATE)
			
	END
END TRY

BEGIN CATCH
	--RAISE AN ERROR, SEND AN EMAIL
	SET @vSUBJECT = 'DB - HGMX PROCESSING ERROR ' + @vGT_DATE;
	SET @vBODY = 'DB - PROCESSING ERROR CHECK FILES ' + @vGT_DATE;

	EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com,prakasha.b@endurance.com'
		,@subject = @vSUBJECT
		,@body = @vBODY;

	THROW
END CATCH
