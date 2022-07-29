USE DBAtools;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ShrinkTempDB]') AND type in (N'P', N'PC'))
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_ShrinkTempDB] AS';
GO

ALTER PROCEDURE [dbo].[usp_ShrinkTempDB]
AS
SET XACT_ABORT, NOCOUNT ON;

DECLARE @free FLOAT;

SELECT TOP (1) @free = CONVERT(float, available_bytes) / total_bytes * 100
FROM sys.dm_os_volume_stats(DB_ID('tempdb'), 1);

IF @free <= 5
    DBCC SHRINKDATABASE(N'tempdb', 10);

GO

GRANT EXECUTE ON [dbo].[usp_ShrinkTempDB] TO [job_execute];
GO

ADD SIGNATURE TO [usp_ShrinkTempDB] BY CERTIFICATE sysadmincert WITH PASSWORD = 'zuViXzxfywPcSQroq9bv';
GO