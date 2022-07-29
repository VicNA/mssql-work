USE DBAtools;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_JobSwitch]') AND type in (N'P', N'PC'))
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_JobSwitch] AS';
GO

ALTER PROCEDURE [dbo].[usp_JobSwitch]
WITH EXECUTE AS OWNER
AS
SET XACT_ABORT, NOCOUNT ON;

DECLARE @job         NVARCHAR(128)
      , @job_enabled TINYINT
      , @state       INT;

SELECT @state = CASE WHEN COUNT(0) = 0 THEN 0
                     WHEN COUNT(1) = SUM(mirroring_role) THEN 1
                     WHEN COUNT(1) = SUM(mirroring_role) - COUNT(1) THEN 2
                     ELSE -1
                END
FROM sys.database_mirroring WHERE mirroring_role IS NOT NULL;

IF @state != -1
BEGIN
    SET @job_enabled = CASE WHEN @state IN (0, 1) THEN 1 WHEN @state = 2 THEN 0 END;

    SET @job = N'DBA: Database FULL backup';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Database DIFF backup';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Database LOG backup';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Copy database backup';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Database index optimize';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Update statistics';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Logger WhoIsActive';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'DBA: Clearing the logger WhoIsActive';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

-- Jobs category CDT
    SET @job = N'ClearNotificationsAndServiceLogs';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'RefreshAuctionStatuses';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;

    SET @job = N'start StatisticCalculate';
    IF (SELECT enabled FROM msdb.dbo.sysjobs WHERE name = @job) != @job_enabled
        EXEC msdb.dbo.sp_update_job @job_name = @job, @enabled = @job_enabled;
END
ELSE
    RAISERROR ('Не все БД переключились', 16, 1);

GO


GRANT EXECUTE ON [dbo].[usp_JobSwitch] TO [job_executor];
GO