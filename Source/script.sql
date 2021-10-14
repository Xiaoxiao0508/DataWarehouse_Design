-- use master

USE DDDM_TPS_1
-- SELECT *
-- FROM SYSOBJECTS
-- WHERE XTYPE='U';

-- GO 

select 1,'NHRM','Patient',URNumber,Gender,YEAR(DOB) AS YOB,Suburb,PostCode,CountryOfBirth,PreferredLanguage ,LivesAlone,Active
,(select TOP 1 Diagnosis From  DDDM_TPS_1.dbo.ConditionDetails CD where cd.URNumber=P.URNumBER),
(SELECT TOP 1 CategoryName 
    FROM DDDM_TPS_1.DBO.PatientCategory PC 
    INNER JOIN DDDM_TPS_1.DBO.TemplateCategory TC 
    ON PC.CategoryID= TC.CategoryID
    WHERE PC.URNumber=P.URNumber),
(SELECT TOP 1 ProcedureDate FROM DDDM_TPS_1.DBO.ConditionDetails CD WHERE CD.URNumber=P.URNumber)
from DDDM_TPS_1.DBO.Patient P



-- SELECT *
-- FROM DDDM_TPS_1.DBO.PatientCategory PC 
-- INNER JOIN DDDM_TPS_1.DBO.TemplateCategory TC 
-- ON PC.CategoryID= TC.CategoryID
-- INNER JOIN DDDM_TPS_1.DBO.ConditionDetails CD 
-- ON PC.URNumber=CD.URNumber



