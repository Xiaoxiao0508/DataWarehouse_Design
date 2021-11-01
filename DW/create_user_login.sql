-- =-----------------------------------------------------in the source db-------------------------------------------
-- ----------------------------------------------create login 
USE [master]
GO
CREATE LOGIN xiaoxiao with PASSWORD='Kangcerking1';
GO
-------------------------------create user for the login in the specific db  you want warehouse to read-only
USE [DDDM_TPS_1]
GO
create USER xiaoxiao FOR LOGIN xiaoxiao
go
EXEC sp_addrolemember 'db_datareader',xiaoxiao;


select * from Patient

-- chekc the user is created in the targed db
-- select name as username,
--       create_date,
--       modify_date,
--       type_desc as type,
--       authentication_type_desc as authentication_type
-- from sys.database_principals
-- where type not in ('A', 'G', 'R', 'X')
--      and sid is not null
--      and name != 'guest'
-- order by username;


-- SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE

-- FROM INFORMATION_SCHEMA. COLUMNS

-- WHERE TABLE_NAME='Staff'