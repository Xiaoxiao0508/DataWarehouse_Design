
-- SELECT NAME FROM SYS.DATABASES;
use hospital
-- IF OBJECT_ID('PATIENT_FILTER_1') IS NOT NULL
-- DROP PROCEDURE DWPATIENT_FILTER_1;
-- GO
-- CREATE PROCEDURE DWPATIENT_FILTER_1
--     @pcustid INT,
--     @pcustname nvarchar(100)
-- AS
-- BEGIN
--     BEGIN TRY 
--     --   filter code goes in ther
--     -- get required data from source-filter
--     -- insert erros into error event

--     insert into LOG() VALUES('PATIENT_FILTER_1',DATETIME.NOW(),'Filter 1 SUCCESSFULLLY EXECUTED')
--     END TRY
--     BEGIN CATCH

--         DECLARE @ERRORMESSAGE NVARCHAR(MAX)=ERROR_MESSAGE();

--        INSERT INTO LOG()VALUES('PATIENT_FILTER_1',DATETIME.NOW(),@ERRORMESSAGE)

--     END CATCH;

-- END;



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

-- BEGIN
-- DECLARE @var NVARCHAR(MAX);
-- EXEC @var = GET_CONNECTION_STRING;
-- PRINT @var;
-- END;

DROP TABLE IF EXISTS LIST_OF_ROWNUMS;
GO
CREATE TABLE LIST_OF_ROWNUMS
(
    ROWNUM NVARCHAR(100)
);

INSERT INTO LIST_OF_ROWNUMS
VALUES(900000005),
    (900000010),
    (900000015),
    (900000020);

BEGIN
    DECLARE @connstring NVARCHAR(max);
    exec @connstring=GET_CONNECTION_STRING
    DECLARE @ROWNUMS NVARCHAR(MAX);
    SELECT @ROWNUMS=COALESCE(@ROWNUMS+',','')+ROWNUM
    FROM LIST_OF_ROWNUMS
    -- PRINT(@ROWNUMS)
    DECLARE @COMMAND NVARCHAR(MAX);
    SET @COMMAND='SELECT *FROM OPENROWSET(''SQLNCLI'',' +
    '''' +@connstring+''','+
    '''SELECT * FROM DDDM_TPS_1.dbo.Patient WHERE URNUMBER NOT IN ('+@ROWNUMS+')'') ;'
    PRINT(@COMMAND);
-- EXEC(@COMMAND);
END;


DROP SEQUENCE IF EXISTS SEQ_DWPATIENTID;
GO
CREATE SEQUENCE SEQ_DWPATIENTID
    -- AS INT
    START WITH 1
    INCREMENT BY 1;
GO


INSERT INTO DWPatient
VALUES
    (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000020, 'Patient', 'Female', 1987, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 1, 1, 'DIAGNOSIS', 2021-09-08, 'Category'),
    (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000010, 'Patient', 'Male', 1966, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 1, 1, 'DIAGNOSIS', 2021-09-08, 'Category'),
    (NEXT VALUE FOR SEQ_DWPATIENTID, 'NHRM', 900000015, 'Patient', 'Female', 1962, 'Knox', '3180', 'AUSTRALIA', 'ENGLISH', 0, 0, 'DIAGNOSIS', 2021-09-19, 'Category')
select *
from DWPatient
INSERT INTO ERROREVENT
VALUES
    ('NHRM', 900000005, 'Patient', 1, 'SKIP', 'description'),
    ('NHRM', 900000025, 'Patient', 1, 'SKIP', 'description')


select *
from ERROREVENT



-- ------------------------------------get required data from source database-----------------------------------------

drop procedure if exists DIM_PATIENT_TRANSFER_GOOD 
-- BEGIN
--     -- ASSUMPTIONS
--     -- FILTERING HAS ALREADY BEEN DONE
--     -- ANY REQUIRED FOR EXCLUSION ARE IN ERROR EVENT TABLE
--       -- PRINT @TO_EXCLUDE
--     -- A LIST OF ALL PATIENTS NOT REQUIRED, ALREADY IN ERROR AND DWPATIENT
--     -- WRITE THE CODE TO GET THE REQUIRED DATA
--     -- INSERT THE DATA TO DW_PATIENT 
--     DECLARE @connstring NVARCHAR(max);
--     exec @connstring=GET_CONNECTION_STRING
    
--     DECLARE @ALREADY_IN_DIM NVARCHAR(MAX);
--     SELECT @ALREADY_IN_DIM=COALESCE(@ALREADY_IN_DIM+',','') + SOURCEID
--     FROM DWPatient
--     WHERE SOURCEDB='NHRM'
--     -- print @ALREADY_IN_DIM

--     DECLARE @IN_ERROR_EVENT NVARCHAR(MAX);
--     SELECT @IN_ERROR_EVENT=COALESCE(@IN_ERROR_EVENT+',','') + SOURCEID
--     FROM ERROREVENT
--     WHERE SOURCEDB='NHRM'
--     -- PRINT @IN_ERROR_EVENT

--     DECLARE @TO_EXCLUDE NVARCHAR(MAX);
--     SET @TO_EXCLUDE=@ALREADY_IN_DIM +','+@IN_ERROR_EVENT

--     -- exclude the data
--     DECLARE @COMMAND NVARCHAR(MAX);
--     SET @COMMAND='SELECT *FROM OPENROWSET(''SQLNCLI'',' +
--     '''' +@connstring+''','+
--     '''SELECT * FROM DDDM_TPS_1.dbo.Patient WHERE URNUMBER NOT IN ('+@TO_EXCLUDE + ')'');'
--     EXEC(@COMMAND)
-- END;



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
    -- print @ALREADY_IN_DIM

    DECLARE @IN_ERROR_EVENT NVARCHAR(MAX);
    SELECT @IN_ERROR_EVENT=COALESCE(@IN_ERROR_EVENT+',','') + SOURCEID
    FROM ERROREVENT
    WHERE SOURCEDB='NHRM'
    -- PRINT @IN_ERROR_EVENT

    DECLARE @TO_EXCLUDE NVARCHAR(MAX);
    SET @TO_EXCLUDE=@ALREADY_IN_DIM +','+@IN_ERROR_EVENT

    -- exclude the data
    DECLARE @COMMAND NVARCHAR(MAX);
    DECLARE @SELECTQUERY NVARCHAR(MAX)
    -- SET @SELECTQUERY= '''SELECT URNumber,Gender,YEAR(DOB) AS YOB,Suburb,PostCode,CountryOfBirth,PreferredLanguage ,LivesAlone,Active,'+
    --             '(select TOP 1 Diagnosis From  DDDM_TPS_1.dbo.ConditionDetails CD where CD.URNumber=P.URNumBER) AS [Diagnosis],' +
    --             '(SELECT TOP 1 CategoryName FROM DDDM_TPS_1.DBO.PatientCategory PC INNER JOIN DDDM_TPS_1.DBO.TemplateCategory TC ON PC.CategoryID = TC.CategoryID'+
    --            'WHERE PC.URNumber=P.URNumber) AS [Category], '+
    --             '(SELECT TOP 1 ProcedureDate FROM DDDM_TPS_1.DBO.ConditionDetails CD WHERE CD.URNumber=P.URNumber) AS [ProcedureDate]'+
    --             'FROM DDDM_TPS_1.DBO.Patient P WHERE URNUMBER NOT IN (' +@TO_EXCLUDE + ')''';

        SET @SELECTQUERY= '''SELECT URNumber,Gender,YEAR(DOB) AS YOB,Suburb,PostCode,CountryOfBirth,PreferredLanguage ,LivesAlone,Active,
                (select TOP 1 Diagnosis From  DDDM_TPS_1.dbo.ConditionDetails CD where CD.URNumber=P.URNumBER) AS [Diagnosis],
                (SELECT TOP 1 CategoryName FROM DDDM_TPS_1.DBO.PatientCategory PC INNER JOIN DDDM_TPS_1.DBO.TemplateCategory TC ON PC.CategoryID = TC.CategoryID
               WHERE PC.URNumber=P.URNumber) AS [Category], 
                (SELECT TOP 1 ProcedureDate FROM DDDM_TPS_1.DBO.ConditionDetails CD WHERE CD.URNumber=P.URNumber) AS [ProcedureDate]
                FROM DDDM_TPS_1.DBO.Patient P WHERE URNUMBER NOT IN (' +@TO_EXCLUDE + ')''';

    PRINT @SELECTQUERY

    DECLARE @INSERTQUERY NVARCHAR(MAX);
    SET @INSERTQUERY='INSERT INTO DWPatient(DWPatientID,SourceDB,SourceID,SourceTable,Gender,YOB,Suburb,CountryOfBirth, PreferredLanguage, LivesAlone, Active, Diagnosis,ProcedureDate,CategoryName) SELECT NEXT VALUE FOR SEQ_DWPATIENTID,''NHRM'',SOURCE.URNumber,''Patient'',SOURCE.Gender,SOURCE.YOB,SOURCE.Suburb,SOURCE.CountryOfBirth,SOURCE. PreferredLanguage,SOURCE.LivesAlone,SOURCE.Active,SOURCE.Diagnosis,SOURCE.ProcedureDate,SOURCE.Category';
print @insertquery
    SET @COMMAND=@INSERTQUERY + ' FROM OPENROWSET(''SQLNCLI'', '  + '''' + @connstring + ''',' + @SELECTQUERY + ' ) SOURCE;'
               
    EXEC(@COMMAND)
END;




-- -------------------------STORE DATA IN A TEMP VARIBALE AND USE IT AS PARAMETER FOR SP----------------------------------

DROP PROCEDURE IF EXISTS var_select_test;
drop procedure if exists TABLE_PARAM_TEST

-- create a new data type
drop type if exists TestTableType;
CREATE type TestTableType as TABLE
(
    -- URNumber NVARCHAR(100),
    -- Email NVARCHAR(256),
    -- Title NVARCHAR(50)
    testid int,
    testdata NVARCHAR(100)
);

GO


CREATE PROCEDURE TABLE_PARAM_TEST @IN_TABLE TestTableType readonly AS
BEGIN
    SELECT 'ZZZ',* FROM @IN_TABLE;
END;
GO 



-- ----------------TEST SELECTING DATA AND STORE IT INTO A CUSTOM DATA TYPE TEMP VARIABLE
create procedure var_select_test as 

Begin
	--		
	declare @testtable Testtabletype;
	
	declare @command nvarchar(max)

	set @command  = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ' +
                    '''Server=dad.cbrifzw8clzr.us-east-1.rds.amazonaws.com;UID=ldtreadonly;PWD=Kitemud$41;'',' +
                    '''SELECT * FROM DDDM_TPS_1.dbo.PATIENT'');'
	insert into @testtable
	exec(@command);

	-- exec ETL_NHRM_PATIENT_FILTER1 @IN_TABLE = @testtable
	-- exec ETL_NHRM_PATIENT_FILTER2 @IN_TABLE  = @testtable
	-- exec ETL_NHRM_PATIENT_FILTER3 @IN_TABLE  = @testtable

	exec TABLE_PARAM_TEST @IN_TABLE = @testtable
END;

GO

EXEC var_select_test;