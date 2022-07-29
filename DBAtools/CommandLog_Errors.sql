USE DBAtools;
GO

--CREATE VIEW [CommandLog_Errors]
--AS
--SELECT [ID]
--     , [DatabaseName]
--     , [SchemaName]
--     , [ObjectName]
--     , [ObjectType]
--     , [IndexName]
--     , [IndexType]
--     , [StatisticsName]
--     , [PartitionNumber]
--     , [ExtendedInfo]
--     , [Command]
--     , [CommandType]
--     , [StartTime]
--     , [EndTime]
--     , [ErrorNumber]
--     , [ErrorMessage]
--  FROM [dbo].[CommandLog]
--WHERE ISNULL(ErrorNumber, -1) != 0;


SELECT [ID]
     , [DatabaseName]
     , [SchemaName]
     , [ObjectName]
     , [ObjectType]
     , [IndexName]
     , [IndexType]
     , [StatisticsName]
     , [PartitionNumber]
     , [ExtendedInfo]
     , [Command]
     , [CommandType]
     , [StartTime]
     , [EndTime]
     , [ErrorNumber]
     , [ErrorMessage]
FROM [dbo].[CommandLog]
WHERE ISNULL(ErrorNumber, -1) != 0
ORDER BY ID DESC;