USE DBAtools;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_JobSwitch]') AND type in (N'P', N'PC'))
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_JobSwitch] AS';
GO

ALTER PROCEDURE [dbo].[usp_JobSwitch]
AS
SET XACT_ABORT, NOCOUNT ON;

DECLARE @job         NVARCHAR(128)
      , @job_enabled TINYINT
      , @state       INT;

SELECT @state = ISNULL(primary_recovery_health, 0)
FROM sys.dm_hadr_availability_group_states;

SET @job_enabled = @state;

SET @job = N'DBA: Database FULL backup';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Database DIFF backup';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Database LOG backup';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Database index optimize';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Update statistics';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Primary replica CHECKDB (R-R-U)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Primary replica CHECKDB (tcryptapi)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Primary replica CHECKDB (Storage)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job_enabled = IIF(@job_enabled = 0, 1, 0);

SET @job = N'DBA: Secondary replica CHECKDB (R-R-U)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Secondary replica CHECKDB (tcryptapi)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

SET @job = N'DBA: Secondary replica CHECKDB (Storage)';
IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
    EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

GO


GRANT EXECUTE ON [dbo].[usp_JobSwitch] TO [job_executor];
GO