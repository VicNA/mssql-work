USE DBAtools;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_DatabaseIntegrityCheck]') AND type in (N'P', N'PC'))
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_DatabaseIntegrityCheck] AS';
GO

ALTER PROCEDURE [dbo].[usp_DatabaseIntegrityCheck]
      @backupObject         NVARCHAR(MAX)
    , @directoryPath        NVARCHAR(MAX) = NULL
    , @backupType           NVARCHAR(4)   = NULL
    , @availabilityGroup    NVARCHAR(1)   = 'N'
    , @cleanupTime          INT           = NULL
    , @cleanupMode          NVARCHAR(MAX) = NULL
AS
SET XACT_ABORT, NOCOUNT ON;

DECLARE @job                NVARCHAR(MAX)
      , @databases          NVARCHAR(MAX)
      , @availabilityGroups NVARCHAR(MAX);

IF @backupType <> 'FULL'
BEGIN
    SELECT @job = j.name
    FROM msdb..sysjobs j
        JOIN msdb..sysjobactivity a ON a.job_id = j.job_id 
    WHERE j.name = N'DBA: Database FULL backup'
        AND a.run_requested_date IS NOT NULL AND a.stop_execution_date IS NULL;
           
    IF @job IS NULL AND @backupType = 'LOG'
        SELECT @job = j.name
        FROM msdb..sysjobs j
            JOIN msdb..sysjobactivity a ON a.job_id = j.job_id 
        WHERE j.name = N'DBA: Database DIFF backup'
            AND a.run_requested_date IS NOT NULL AND a.stop_execution_date IS NULL;

    IF @job IS NOT NULL
    BEGIN
        PRINT 'The task is skipped. The "' + @job + '" task is running"';
        RETURN;
    END
END

IF @AvailabilityGroup = 'Y'
    SET @availabilityGroups = @backupObject;
ELSE
    IF @backupObject IN ('USER_DATABASES', 'SYSTEM_DATABASES')
    BEGIN
        SET @databases = @backupObject;

        IF @databases = 'USER_DATABASES'
            SELECT @databases = ISNULL(@databases, '') + ', -' + name
            FROM sys.databases
            WHERE name IN ('DBA', 'Baseline', 'DBAtools', 'ReportServer', 'ReportServerTempDB');
    END

EXEC [dbo].[DatabaseBackup]
  @Databases                           = @databases
, @Directory                           = @directoryPath
, @BackupType                          = @backupType
, @CleanupTime                         = @cleanupTime
, @CleanupMode                         = @cleanupMode
, @Compress                            = 'Y'
, @ChangeBackupType                    = 'Y'
, @CheckSum                            = 'Y'
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

GRANT EXECUTE ON [dbo].[DatabaseBackup] TO [job_execute]
GO
GRANT EXECUTE ON [dbo].[DatabaseIntegrityCheck] TO [job_execute]
GO
GRANT EXECUTE ON [dbo].[IndexOptimize] TO [job_execute]
GO
GRANT EXECUTE ON [dbo].[usp_DatabaseBackup] TO [job_execute];
GO