USE DBAtools;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_DatabaseBackup]') AND type in (N'P', N'PC'))
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_DatabaseBackup] AS';
GO

ALTER PROCEDURE [dbo].[usp_DatabaseBackup]
      @databases            NVARCHAR(MAX) = NULL
    , @availabilityGroups   NVARCHAR(MAX) = NULL
    , @directory            NVARCHAR(MAX) = NULL
    , @backupType           NVARCHAR(4)   = NULL
    , @cleanupTime          INT           = NULL
    , @cleanupMode          NVARCHAR(MAX) = NULL
    , @checkSum             NVARCHAR(1)   = 'Y'
AS
SET XACT_ABORT, NOCOUNT ON;

DECLARE @job NVARCHAR(MAX);

IF @backupType = 'DIFF'
BEGIN
    SELECT @job = j.name
    FROM msdb..sysjobs j
        JOIN msdb..sysjobactivity a ON a.job_id = j.job_id
    WHERE j.name = N'DBA: Database FULL backup'
        AND a.run_requested_date IS NOT NULL AND a.stop_execution_date IS NULL
        AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity);

    IF @job IS NOT NULL
    BEGIN
        PRINT 'The task is skipped. The "' + @job + '" task is running"';
        RETURN;
    END
END

IF @databases = 'USER_DATABASES'
    SELECT @databases = ISNULL(@databases, '') + ', -' + name
    FROM sys.databases
    WHERE name IN ('DBA', 'Baseline', 'DBAtools', 'ReportServer', 'ReportServerTempDB');

EXEC [dbo].[DatabaseBackup]
  @Databases                           = @databases
, @Directory                           = @directory
, @BackupType                          = @backupType
, @CleanupTime                         = @cleanupTime
, @CleanupMode                         = @cleanupMode
, @Compress                            = 'Y'
, @ChangeBackupType                    = 'Y'
, @CheckSum                            = @checkSum
, @AvailabilityGroups                  = @availabilityGroups
, @DirectoryStructure                  = '{DatabaseName}'
, @AvailabilityGroupDirectoryStructure = '{ClusterName}${AvailabilityGroupName}{DirectorySeparator}{DatabaseName}'
, @FileName                            = '{ServerName}${InstanceName}_{DatabaseName}_{Year}_{Month}_{Day}_{Hour}{Minute}{Second}.{FileExtension}'
, @AvailabilityGroupFileName           = '{ClusterName}${AvailabilityGroupName}_{DatabaseName}_{Year}_{Month}_{Day}_{Hour}{Minute}{Second}.{FileExtension}'
, @FileExtensionFull                   = 'bak'
, @FileExtensionDiff                   = 'diff'
, @FileExtensionLog                    = 'trn'
, @DatabaseOrder                       = 'DATABASE_SIZE_ASC'
, @LogToTable                          = 'Y';

GO

GRANT EXECUTE ON [dbo].[CommandExecute] TO [job_executor]
GO
GRANT EXECUTE ON [dbo].[DatabaseBackup] TO [job_executor]
GO
GRANT EXECUTE ON [dbo].[DatabaseIntegrityCheck] TO [job_executor]
GO
GRANT EXECUTE ON [dbo].[IndexOptimize] TO [job_executor]
GO
GRANT EXECUTE ON [dbo].[usp_DatabaseBackup] TO [job_executor];
GO