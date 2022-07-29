USE DBAtools;
GO

--CREATE VIEW [CommandLog_CheckDB]
--AS
--SELECT [ID]
--     , [DatabaseName]
--     , [Command]
--     , [CommandType]
--     , [StartTime]
--     , [EndTime]
--     , [ErrorNumber]
--     , [ErrorMessage]
--FROM [dbo].[CommandLog]
--WHERE CommandType = 'DBCC_CHECKDB';


SELECT [ID]
     , [DatabaseName]
     , [Command]
     , [CommandType]
     , [StartTime]
     , [EndTime]
     , [ErrorNumber]
     , [ErrorMessage]
FROM [dbo].[CommandLog]
WHERE CommandType = 'DBCC_CHECKDB'
ORDER BY ID DESC;