USE [GTStage_Matt]
GO
/****** Object:  StoredProcedure [dbo].[HGMX_WRAPPER_EXCEPTION]    Script Date: 12/2/2020 10:29:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* Description: WRAPPER EXCEPTION SPROC FOR HGMX CASH SPS
	This stored procedure is run to generate all of the cash
	journal entries for only the day after the last successfully 
	run day when a high suspense amount causes 
	the main Wrapper SPS to error out.  

	The Wrapper Exception SPS will error out if the following conditions are met:
		1. If any of the Cash Receipt or Sales journal entries are unbalanced by more than
			$100, the Wrapper Exception SPS terminates and an "Unbalanced Entry" email is sent.
		2. If the Wrapper Exception fails to execute any of the individual Cash stored procedures for any reason other than 
			an unbalanced entry and high suspense amount it will terminate and a "DB - HGMX PROCESSING ERROR" email is sent.
	
	The individual Cash SPROCs that the Wrapper Exeption SPROC executes are:

		EXEC HGMX_DLOCAL_SALES @vGT_DATE;
		EXEC HGMX_DLOCAL_CASH @vGT_DATE;
		EXEC HGMX_PayU_Sales @vGT_DATE;
		EXEC HGMX_PAYPAL_SALES @vGT_DATE;	
		EXEC HGMX_OVERPAYMENT_SALES @vGT_DATE;

	  */


ALTER     PROCEDURE [dbo].[HGMX_WRAPPER_EXCEPTION] AS

SET NOCOUNT ON;

--Declaring variables for e-mail subject and body to use in Exceptions e-mails.

DECLARE @vSUBJECT VARCHAR(255)
DECLARE @VBODY VARCHAR(255)
DECLARE @PROC_DATE DATETIME


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

BEGIN TRY
--	WHILE (@PROC_DATE <= @END_DATE)
--	BEGIN
		SET @vGT_DATE = FORMAT(@PROC_dATE, 'yyyyMMdd')
		SET @START_DATE = getdate();

		DECLARE @vDEL_DATE VARCHAR(50);

		SET @vDEL_DATE = 'ACL_' + SUBSTRING(@vGT_DATE, 5, 4) + SUBSTRING(@vGT_DATE, 1, 4);

		DELETE
		FROM GTSTAGE.dbo.COMMON_JE
		WHERE BATCHID_CALC = @vDEL_DATE
			AND BRAND_CALC = 'HGMX';
			SELECT * FROM GTSTAGE.dbo.COMMON_JE
		DELETE
		FROM GTSTAGE.dbo.COMMON_EXCEPTION
		WHERE BATCHID_calc = @vDEL_DATE
			AND BRAND_calc = 'HGMX';

--Run Stored Procedures

		/* Executing the five HGMX Cash SPS which we use to build
		   a day's worth of Journal Entries. */ 

		EXEC HGMX_DLOCAL_SALES @vGT_DATE;
		EXEC HGMX_DLOCAL_CASH @vGT_DATE;
		EXEC HGMX_PayU_Sales @vGT_DATE;
		EXEC HGMX_PAYPAL_SALES @vGT_DATE;	
		EXEC HGMX_OVERPAYMENT_SALES @vGT_DATE;

--BALANCE TESTS
		--HGMX PayU Sales JE
					/*The HGMX Litle Sales JE is checked whether it is balanced or not.
					An Unbalanced Exceptions email is sent out if the difference between sum 
					and the credits is greater than $100 and the wrapper would stop there. */
	
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PAYU_JE_Final
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX  Unbalanced Entries "HGMX_PAYU_JE_Final" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_PAYU_JE_Final" ' + @vGT_DATE + ' are now available.';

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
			EXECUTE dbo.sp_balance_entry_cp_NO_CR 'HGMX_PAYU_JE_Final'
				,'061-11045-000';

--DLOCAL CASH JE
				/*This code block checks to see if the HGMX DLOCAL CASH JE is balanced or not.
				If the difference between the sum and the credits is greater than $100 than 
				the Wrapper stops here and an Unbalanced Exceptions email is sent out. */
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLocal_Cash_JE
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX Unbalanced Entries "HGMX_DLocal_Cash_JE" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_DLocal_Cash_JE" ' + @vGT_DATE + ' are now available.';

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


--HGMX_DLOCAL_SALES JE
			/*This code block checks to see if the HGMX DLOCAL Sales JE is balanced or not.
				If the difference between the sum and the credits is greater than $100 than 
				the Wrapper stops here and an Unbalanced Exceptions email is sent out. */
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_DLOCAL_SALES_JE_FINAL
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX Unbalanced Entries "HGMX_DLOCAL_SALES_JE_FINAL" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_DLOCAL_SALES_JE_FINAL" ' + @vGT_DATE + ' are now available.';

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

--HGMX_PAYPAL_SALES JE
			/*This code block checks to see if the HGMX PAYPAL SALES JE is balanced or not.
				If the difference between the sum and the credits is greater than $100 than 
				the Wrapper stops here and an Unbalanced Exceptions email is sent out. */
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_PP_JE_FINAL
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX Unbalanced Entries "HGMX_PP_JE_Final" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_PP_JE_Final" ' + @vGT_DATE + ' are now available.';

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

--HGMX OVERPAYMENT SALES JE
			/*This code block checks to see if the HGMX OVERPAYMENT SALES JE is balanced or not.
				If the difference between the sum and the credits is greater than $100 than 
				the Wrapper stops here and an Unbalanced Exceptions email is sent out. */
		IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_OVERPAYMENT_JE
					GROUP BY CHECKBOOKID
					)) > 100
			--SEND EMAIL ABOUT UNBALANCE GREATER THAN 100 AND STOP JOB
		BEGIN
			SET @vSUBJECT = 'DB - HGMX Unbalanced Entries "HGMX_OVERPAYMENT_JE" ' + @vGT_DATE;
			SET @vBODY = 'DB - HGMX Unbalanced Entries for "HGMX_OVERPAYMENT_JE" ' + @vGT_DATE + ' are now available.';

			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com;prakasha.b@endurance.com'
				,@subject = @vSUBJECT
				,@body = @vBODY;

			RETURN;
		END
		ELSE IF ABS((
					SELECT (SUM(DEBIT) - SUM(credit))
					FROM HGMX_OVERPAYMENT_JE
					GROUP BY CHECKBOOKID
					)) > 0
			--RUN BALANCE ENTRY
			EXECUTE dbo.sp_balance_entry_cp 'HGMX_OVERPAYMENT_JE'
				,'061-11045-000';		

--EXCEPTION TESTS
--IF ABS((
--					SELECT SUM(UN.DEBIT) - SUM(UN.CREDIT)
--					FROM (
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_Litle_Final_JE
						
--						UNION
						
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_AMEX_Final_JE
						
--						UNION
						
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_AMEX_Cash_JE_Final 
						
--						UNION
						
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_Litle_Cash_JE_Final
						
--						UNION
						
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_PP_JE_Final
						
--						UNION
						
--						SELECT credit
--							,debit
--							,account
--						FROM HGMX_Checks_JE
						
						
--						) UN
--					WHERE UN.ACCOUNT IN ('073-11045-000')
--						--GROUP BY UN.ACCOUNT
--					)) > 5000
--		BEGIN
--			--SEND EMAIL ABOUT HIGH SUSPENSE AND STOP JOB
--			SET @vSUBJECT = 'DB - HGMX High Exceptions ' + @vGT_DATE;
--			SET @vBODY = 'DB - HGMX High Exceptions ' + @vGT_DATE + ' are now available.';

--			EXEC msdb.dbo.sp_send_dbmail @recipients = 'acl_reporting@endurance.com;prakasha.b@endurance.com'
--				,@subject = @vSUBJECT
--				,@body = @vBODY

--			RETURN;
--		END


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

---- HGMX Overpayment_JE
INSERT INTO COMMON_JE (CHECKBOOKID_CALC, BATCHID_CALC, TRANTYPE_CALC, TRANDATE_CALC, SRCDOC_CALC, CURRID_CALC, REFRENCE_CALC, ACCOUNT_CALC, DEBIT, CREDIT, DISTREF_CALC, KEY1_CALC, REVERSEDATE_CALC, UNIQUEID_CALC, DOCAMT_CALC, DISTYPE_CALC, BRAND_CALC, MERCHANT_CALC)
SELECT CHECKBOOKID, BATCHID, TRANTYPE, TRANDATE, SRCDOC, CURRID, REFERENCE, ACCOUNT, DEBIT, CREDIT, DISTREF, KEY1, REVERSEDATE, UNIQUEID, DOCAMT, DISTYPE, 'HGMX', 'Overpayment_JE'
FROM HGMX_OVERPAYMENT_JE


		--COMMON EXCEPTION INSERTS


		--####################
		--     CREATE EXTRACTS HERE
		--####################
		EXECUTE [DMFLogging].[dbo].[sp_HGMX_JE_Feed] @vGT_DATE;

		/* If Wrapper Exception SPS runs up to this point, insert the run date 
		into the following tables: JE_RUN_HISTORY & EXCEPTION_RUN_HISTORY
		so that the following day can get run the next time the Wrapper is executed. */

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

		INSERT INTO EXCEPTION_RUN_HISTORY (
			run_id
			,start_date
			,stop_Date
			,date_run
			,brand_table
			, RUN_TYPE
			)
		SELECT max(run_id) + 1
			,@START_DATE
			,getdate()
			,@PROC_DATE
			,'GT_PROCESSED_HGMX'
			,'EXCEPTION'
		FROM EXCEPTION_RUN_HISTORY;

		
		SET @vSUBJECT = 'DB - HGMX Journal Entries and Exception Reports ' + @vGT_DATE;
		SET @vBODY = 'DB - Journal Entries and Exception Reports for ' + @vGT_DATE + ' are now available.';

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com'
			,@subject = @vSUBJECT
			,@body = @vBODY;

		EXEC HGMX_DROPS

		SET @PROC_DATE = DATEADD(DD, 1, @PROC_DATE)
			
--	END
END TRY

BEGIN CATCH
	--RAISE AN ERROR, SEND AN EMAIL
	SET @vSUBJECT = 'DB - HGMX PROCESSING ERROR ' + @vGT_DATE;
	SET @vBODY = 'DB - PROCESSING ERROR CHECK FILES ' + @vGT_DATE;

	EXEC msdb.dbo.sp_send_dbmail @recipients = 'ACL_REPORTING@endurance.com'
		,@subject = @vSUBJECT
		,@body = @vBODY;

	THROW
END CATCH
