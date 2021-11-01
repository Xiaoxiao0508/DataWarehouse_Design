
-- SELECT NAME FROM SYS.DATABASES;
use hospital

-- SELECT Patient.URNumber
-- FROM 
-- OPENROWSET('SQLNCLI','Server=dad.cbrifzw8clzr.us-east-1.rds.amazonaws.com;UID=xiaoxiao;PWD=Kangcerking1;','SELECT * FROM [DDDM_TPS_1].dbo.Patient') Patient;
DROP FUNCTION IF EXISTS GET_CONNECTION_STRING
GO
CREATE FUNCTION GET_CONNECTION_STRING() returns NVARCHAR(MAX) as 
BEGIN
    return 'Server=db.cgau35jk6tdb.us-east-1.rds.amazonaws.com;UID=xiaoxiao;PWD=Kangcerking1;';
END;
GO

-- DROP TABLE IF EXISTS LIST_OF_ROWNUMS;
-- GO
-- CREATE TABLE LIST_OF_ROWNUMS
-- (
--     ROWNUM NVARCHAR(100)
-- );

-- INSERT INTO LIST_OF_ROWNUMS
-- VALUES(900000005),
--     (900000010),
--     (900000015),
--     (900000020);

-- BEGIN
--     DECLARE @connstring NVARCHAR(max);
--     exec @connstring=GET_CONNECTION_STRING
--     DECLARE @ROWNUMS NVARCHAR(MAX);
--     SELECT @ROWNUMS=COALESCE(@ROWNUMS+',','')+ROWNUM
--     FROM LIST_OF_ROWNUMS
--     -- PRINT(@ROWNUMS)
--     DECLARE @COMMAND NVARCHAR(MAX);
--     SET @COMMAND='SELECT *FROM OPENROWSET(''SQLNCLI'',' +
--     '''' +@connstring+''','+
--     '''SELECT * FROM DDDM_TPS_1.dbo.Patient WHERE URNumber NOT IN ('+@ROWNUMS+')'') ;'
--     PRINT(@COMMAND);
-- EXEC(@COMMAND);
-- END;


DROP SEQUENCE IF EXISTS SEQ_DWPATIENTID;
GO
CREATE SEQUENCE SEQ_DWPATIENTID
    -- AS INT
    START WITH 1
    INCREMENT BY 1;
GO


-- INSERT INTO DWPatient
-- VALUES
--     (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000020, 'Patient', 'Female', 1987, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 1, 1, 'DIAGNOSIS', 2021-09-08, 'Category'),
--     (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000010, 'Patient', 'Male', 1966, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 1, 1, 'DIAGNOSIS', 2021-09-08, 'Category'),
--     (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000015, 'Patient', 'Female', 1962, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 0, 0, 'DIAGNOSIS', 2021-09-19, 'Category')
-- select *
-- from DWPatient
-- INSERT INTO ERROREVENT
-- VALUES
--     ('NHRM', 900000005, 'Patient', 2012-02-21,1, 'SKIP', 'description'),
--     ('NHRM', 900000025, 'Patient',2005-09-10, 1, 'SKIP', 'description')


-- select *
-- from ERROREVENT

-- ---------------------------------------------The TRANSFER_GOOD SP-------------------------------------------------------------
-- ------------------------------------get required data from source database------------------------------------------------------

drop procedure if exists DIM_PATIENT_TRANSFER_GOOD 
GO
CREATE PROCEDURE DIM_PATIENT_TRANSFER_GOOD AS
BEGIN
    -- ASSUMPTIONS
    -- FILTERING HAS ALREADY BEEN DONE
    -- ANY REQUIRED FOR EXCLUSION ARE IN ERROR EVENT TABLE
      -- PRINT @TO_EXCLUDE
    -- A LIST OF ALL PATIENTS NOT REQUIRED, ALREADY IN ERROR AND DWPATIENT
    -- WRITE THE CODE TO GET THE REQUIRED DATA
    -- INSERT THE DATA TO DW_PATIENT 
    DECLARE @connstring NVARCHAR(max);
    exec @connstring=GET_CONNECTION_STRING
    
    DECLARE @ALREADY_IN_DIM NVARCHAR(MAX);
    SELECT @ALREADY_IN_DIM=COALESCE(@ALREADY_IN_DIM+',','') + SOURCEID
    FROM DWPatient
    WHERE SOURCEDB='NHRM'
    DECLARE @IN_ERROR_EVENT NVARCHAR(MAX);
    SELECT @IN_ERROR_EVENT=COALESCE(@IN_ERROR_EVENT+',','') + SOURCEID
    FROM ERROREVENT
    WHERE SOURCEDB='NHRM'
    -- PRINT @IN_ERROR_EVENT

    DECLARE @TO_EXCLUDE NVARCHAR(MAX);
    SET @TO_EXCLUDE=@ALREADY_IN_DIM +','+@IN_ERROR_EVENT

    -- exclude the data already in DIM and errorevent
    DECLARE @COMMAND NVARCHAR(MAX);
    DECLARE @SELECTQUERY NVARCHAR(MAX)
        SET @SELECTQUERY= '''SELECT URNumber,Gender,YEAR(DOB) AS YOB,Suburb,PostCode,CountryOfBirth,PreferredLanguage ,LivesAlone,Active,
                (select TOP 1 Diagnosis From  DDDM_TPS_1.dbo.ConditionDetails CD where CD.URNumber=P.URNumBER) AS [Diagnosis],
                (SELECT TOP 1 CategoryName FROM DDDM_TPS_1.DBO.PatientCategory PC INNER JOIN DDDM_TPS_1.DBO.TemplateCategory TC ON PC.CategoryID = TC.CategoryID
               WHERE PC.URNumber=P.URNumber) AS [Category], 
                (SELECT TOP 1 ProcedureDate FROM DDDM_TPS_1.DBO.ConditionDetails CD WHERE CD.URNumber=P.URNumber) AS [ProcedureDate]
                FROM DDDM_TPS_1.DBO.Patient P WHERE URNumber NOT IN (' +@TO_EXCLUDE + ')''';

    -- PRINT @SELECTQUERY

    DECLARE @INSERTQUERY NVARCHAR(MAX);
    SET @INSERTQUERY='INSERT INTO DWPatient(DWPatientID,SourceDB,SourceID,SourceTable,Gender,YOB,Suburb,Postcode,CountryOfBirth, PreferredLanguage, LivesAlone, Active, Diagnosis,ProcedureDate,CategoryName) SELECT NEXT VALUE FOR SEQ_DWPATIENTID,''NHRM'',SOURCE.URNumber,''Patient'',SOURCE.Gender,SOURCE.YOB,SOURCE.Suburb,SOURCE.CountryOfBirth,SOURCE. PreferredLanguage,SOURCE.LivesAlone,SOURCE.Active,SOURCE.Diagnosis,SOURCE.ProcedureDate,SOURCE.Category';
    SET @COMMAND=@INSERTQUERY + ' FROM OPENROWSET(''SQLNCLI'', '  + '''' + @connstring + ''',' + @SELECTQUERY + ' ) SOURCE;'             
    EXEC(@COMMAND)
END;

-- SELECT * FROM DWPatient



-- -------------------------STORE DATA IN A TEMP VARIBALE AND USE IT AS PARAMETER FOR SP----------------------------------

DROP PROCEDURE IF EXISTS ETL_NHRM_PATIENT
drop procedure if exists TABLE_PARAM_TEST
DROP PROCEDURE IF EXISTS ETL_NHRM_PATIENT_FILTER1;


-- create a new data type
drop type if exists TestTableType;
CREATE type TestTableType as TABLE
(
    URNumber NVARCHAR(50) NOT NULL,
    Gender NVARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Suburb NVARCHAR(50) NOT NULL,
    PostCode NVARCHAR(4) NOT NULL,
    CountryOfBirth NVARCHAR(50) NOT NULL,
    PreferredLanguage NVARCHAR(50) NOT NULL,
    LivesAlone BIT NOT NULL,
    Active BIT NOT NULL
);

GO

-- -------------------------------------------Patient_Filter SP------------------------------------------------------------------

CREATE PROCEDURE ETL_NHRM_PATIENT_FILTER1 @temp_table TestTableType readonly AS
BEGIN
	BEGIN TRY
			DECLARE @SOURCE_PROC NVARCHAR(50) = 'ETL_NHRM_PATIENT_FILTER1' , @ETL_EVENT_DATE DATETIME = SYSDATETIME(), @ETL_EVENT_DETAILS NVARCHAR(50) = 'Transfer Data from NHRM Patient'
			-- INSERT INTO ERROREVENT(ERRORID, SOURCEID, SOURCETABLE, FILTERID, DATE_TIME, [ACTION])
			-- SELECT NEXT VALUE FOR ERRORID_SEQ, URNumber, 'PATIENT', 1, (SELECT SYSDATETIME()), 'MODIFY'
            -- use identity for ERRORID
            INSERT INTO ERROREVENT(SOURCEDB,SOURCEID, SOURCETABLE, FILTERID, DATE_TIME, [ACTION])
			SELECT 'NHRM',URNumber, 'PATIENT', 1, (SELECT SYSDATETIME()), 'MODIFY'
			FROM @temp_table
			WHERE YEAR(DOB)>YEAR(SYSDATETIME());
			
			INSERT INTO LOG (SOURCEPROCEDURE, EVENTDATETIME, EVENTDETAILS) 
			VALUES (@SOURCE_PROC, @ETL_EVENT_DATE, @ETL_EVENT_DETAILS);
	END TRY
	BEGIN CATCH

			 BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                INSERT INTO LOG (SOURCEPROCEDURE, EVENTDATETIME, EVENTDETAILS)  
				VALUES (@SOURCE_PROC, @ETL_EVENT_DATE, @ERRORMESSAGE);
			 END; 
	END CATCH

END



GO
-- -------------------------------------------------------THE ETL_NHRM_PATIENT SP-----------------------------------------------------------
-- ---------------- STORE select result INTO A CUSTOM DATA TYPE TEMP VARIABLE and pass it to SP--------
create procedure ETL_NHRM_PATIENT as 

Begin
	--		
	declare @testtable Testtabletype;
	
	declare @command nvarchar(max)

	set @command  = 'SELECT URNumber,Gender,Dob,Suburb,Postcode,Countryofbirth,Preferredlanguage,LivesAlone,Active FROM OPENROWSET(''SQLNCLI'', ' +
                    '''Server=dad.cbrifzw8clzr.us-east-1.rds.amazonaws.com;UID=ldtreadonly;PWD=Kitemud$41;'',' +
                    '''SELECT * FROM DDDM_TPS_1.dbo.PATIENT'');'
	insert into @testtable
	exec(@command);

	exec ETL_NHRM_PATIENT_FILTER1 @temp_table = @testtable;
    exec DIM_PATIENT_TRANSFER_GOOD;
END;

GO

-- --------------------------------------------------------Final ETL_NHRM SP--------------------------------------------------------------
IF OBJECT_ID('ETL_NHRM') IS NOT NULL
DROP PROCEDURE ETL_NHRM;
GO
CREATE PROCEDURE ETL_NHRM AS 
BEGIN
	   EXEC ETL_NHRM_PATIENT
	 --EXEC ETL_NHRM_MEASUREMENT
	 --EXEC ETL_NHRM_DATAPOINT
END;

EXEC ETL_NHRM;