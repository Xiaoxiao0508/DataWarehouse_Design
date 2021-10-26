

--------------------------------------------------------in the dw warehouse-(connect to the dw db)-----------------------------------------
SELECT Patient.URNumber,Patient.Gender,Patient.Dob,Patient.Suburb,Patient.Postcode,Patient.Countryofbirth,Patient.Preferredlanguage,Patient.Active
FROM
OPENROWSET('SQLNCLI', 'Server=db.cgau35jk6tdb.us-east-1.rds.amazonaws.com;UID=bgmanager;PWD=beng123;', 
'SELECT * FROM DDDM_TPS_1.dbo.PATIENT') patient;

use hospital

-- SELECT table_catalog[database],table_schema [schema],table_name name,table_type type
-- FROM INFORMATION_SCHEMA.TABLES

IF OBJECT_ID('ERROREVENT') IS NOT NULL
DROP TABLE ERROREVENT;
GO
IF OBJECT_ID('Treating') IS NOT NULL 
DROP TABLE  Treating
IF OBJECT_ID('DataPointRecord') IS NOT NULL 
DROP TABLE  DataPointRecord
IF OBJECT_ID('Intervention') IS NOT NULL 
DROP TABLE  Intervention
IF OBJECT_ID('DWPatient') IS NOT NULL 
DROP TABLE  DWPatient
IF OBJECT_ID('DWStaff') IS NOT NULL 
DROP TABLE  DWStaff
IF OBJECT_ID('DWMeasurement') IS NOT NULL 
DROP TABLE  DWMeasurement
IF OBJECT_ID('DWRecord') IS NOT NULL 
DROP TABLE  DWRecord
IF OBJECT_ID('DWDate') IS NOT NULL 
DROP TABLE  DWDate
GO
IF OBJECT_ID('GENDERSPELLING') IS NOT NULL
DROP TABLE GENDERSPELLING;
GO
--  nedd to modify this table later---
CREATE TABLE DWDate(
    DWDateID INT IDENTITY(1,1)
    PRIMARY KEY (DWDateID)
)
CREATE TABLE DWPatient(
    -- DWPatientID int IDENTITY(00000001,1)CHECK (LEN(DWPatientID)=8),
    -- DWPatientID INT,
    DWPatientID NVARCHAR(50),
    SourceDB NVARCHAR(50) NOT NULL,
    SourceID NVARCHAR(50) NOT NULL,
    SourceTable NVARCHAR(50) NOT NULL,
    Gender NVARCHAR(50) NOT NULL,CHECK (Gender in ('Male','Female','Other')),
    YOB INT CHECK (LEN(YOB)=4),
    Suburb NVARCHAR(50) NOT NULL,
    Postcode INT CHECK (LEN(Postcode)=4),
    CountryOfBirth NVARCHAR(50) NOT NULL,
    PreferredLanguage NVARCHAR(50) NOT NULL,
    LivesAlone Bit NOT NULL CHECK(LivesAlone IN (0,1)),
    Active Bit NOT NULL CHECK(Active IN (0,1)),
    -- Diagnosis  NVARCHAR(500) NOT NULL,
    Diagnosis  NVARCHAR(500),
    -- ProcedureDate DATETIME NOT NULL,
    ProcedureDate DATETIME,
    -- CategoryName  NVARCHAR(50) NOT NULL,
    CategoryName  NVARCHAR(50) ,
    PRIMARY KEY  (DWPatientID)
    
)
CREATE TABLE DWStaff(
    DWStaffID int IDENTITY(0001,1)CHECK (LEN(DWStaffID)=4),
    SourceDB NVARCHAR(50) NOT NULL,
    SourceID  INT NOT NULL,
    SourceTable NVARCHAR(50) NOT NULL,
    StaffType NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    Surname NVARCHAR(50) NOT NULL,
    PRIMARY KEY  (DWStaffID)
)
CREATE TABLE Treating(
   DWTreatingID NVARCHAR(50) CHECK (LEN(DWTreatingID)=8),
    -- DWPatientID INT CHECK (LEN(DWPatientID)=6),
    DWPatientID NVARCHAR(50),
    DWStaffID INT ,CHECK (LEN(DWStaffID)=4),
    DWStartDateID INT NOT NULL,
    DWEndDateID INT,
    PRIMARY KEY (DWTreatingID),
    FOREIGN KEY (DWPatientID) REFERENCES DWPatient,
    FOREIGN KEY (DWStaffID) REFERENCES DWStaff,
    FOREIGN KEY (DWStartDateID) REFERENCES DWDate,
    FOREIGN KEY (DWEndDateID) REFERENCES DWDate
)
CREATE TABLE DWMeasurement(
    DWMeasurementID int IDENTITY(001,1)CHECK (LEN(DWMeasurementID)=3),
    SourceDB NVARCHAR(50) NOT NULL,
    SourceID INT NOT NULL,
SourceTable NVARCHAR(50) NOT NULL,
    DataPointNumber INT,
    MeasurementName NVARCHAR(50) NOT NULL,
    UpperLimit INT NOT NULL CHECK(UpperLimit>=0 and UpperLimit<=10),
    LowerLimit INT NOT NULL CHECK(LowerLimit>=0 and LowerLimit<=10),
    Frequency INT NOT NULL,
    [Name] NVARCHAR(50) NOT NULL,
    CHECK(LowerLimit<UpperLimit),
    PRIMARY KEY (DWMeasurementID)
)
CREATE TABLE DataPointRecord(
    DWDataPointRecordID NVARCHAR(50) CHECK (LEN(DWDataPointRecordID)=8),
    -- DWPatientID INT,
    DWPatientID NVARCHAR(50),
    DWMeasurementID INT,
    DWDateID INT NOT NULL,
    [Value] Float NOT NULL,
    Frequency INT NOT NULL,
    FrequencySetDate DATETIME NOT NULL,
    PRIMARY KEY (DWDataPointRecordID),
    FOREIGN KEY (DWPatientID) REFERENCES DWPatient,
    FOREIGN KEY (DWMeasurementID) REFERENCES DWMeasurement,
    FOREIGN KEY (DWDateID) REFERENCES DWDate
)


CREATE TABLE DWRecord(
    DWRecordID int IDENTITY(0001,1)CHECK (LEN(DWRecordID)=8),
    SourceDB NVARCHAR(50) NOT NULL,
    SourceID INT NOT NULL,
    SourceTable NVARCHAR(50) NOT NULL,
    RecordType NVARCHAR(50) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    PRIMARY KEY (DWRecordID)
)

CREATE TABLE Intervention(
    DWInterventionID NVARCHAR(50) CHECK (LEN(DWInterventionID)=8),
    -- DWPatientID INT,
    DWPatientID NVARCHAR(50),
    DWRecordID INT,
    DWDateID INT NOT NULL,
    Note NVARCHAR(MAX),
    PRIMARY KEY (DWInterventionID),
    FOREIGN KEY (DWPatientID) REFERENCES DWPatient,
    FOREIGN KEY (DWRecordID) REFERENCES DWRecord,
    FOREIGN KEY (DWDateID) REFERENCES DWDate
)
-- -------------------------------------------------------------------------------
CREATE TABLE ERROREVENT
(
    -- ERRORID INTEGER IDENTITY(1,1),
    SOURCEDB NVARCHAR(50),
    SOURCEID NVARCHAR(50),
    SOURCETABLE NVARCHAR(50),
    FILTERID int,
    -- [DATETIME] DATETIME,
    [ACTION] NVARCHAR(50),
    [DESCRIPTION] NVARCHAR(MAX),
    CONSTRAINT [ACTION] CHECK ([ACTION] IN ('SKIP','MODIFY'))
)


-- CREATE TABLE GENDERSPELLING
-- (
--     [Invalid Value] NVARCHAR(10),
--     [New Value] NVARCHAR(1)
-- )
-- INSERT INTO  GENDERSPELLING
--     ([Invalid Value], [New Value] )
-- VALUES

--     ('MAIL', 'M'),
--     ('WOMAN', 'F'),
--     ('FEM', 'F'),
--     ('FEMALE', 'F'),
--     ('MALE', 'M'),
--     ('GENTLEMAN', 'M'),
--     ('MM', 'M'),
--     ('FF', 'F'),
--     ('FEMAIL', 'F')


IF OBJECT_ID('LOG') IS NOT NULL
DROP TABLE LOG;
GO

CREATE TABLE LOG(
    SOURCEPROCEDURE NVARCHAR(100),
    EVENTDATETIME DATETIME,
    EVENTDETAILS NVARCHAR(MAX)
)