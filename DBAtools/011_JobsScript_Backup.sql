/*
********************************************
****************** БЭКАПЫ ******************
********************************************
*/

/*
    Task:
        DBA: Database FULL backup
    Step 1:
        Backup
*/

-- Версия для экземпляра с кластером --

EXEC dbo.usp_DatabaseBackup
  @availabilityGroups = 'CryptAG'
, @directoryPath = '\\rebacker\Backup'
, @backupType = 'FULL'
, @cleanupTime = 1
, @cleanupMode = 'BEFORE_BACKUP'

-- Версия для обычного экземпляра --

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @databases = 'USER_DATABASES'
, @directoryPath = 'S:\BackupSQL\UserDB'
, @backupType = 'FULL'
, @cleanupTime = 1
, @cleanupMode = 'BEFORE_BACKUP'


/*
    Task:
        DBA: Database DIFF backup
    Step 1:
        Backup
*/

-- Версия для экземпляра с кластером --

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @availabilityGroups = 'CryptAG'
, @directoryPath = '\\rebacker\Backup'
, @backupType = 'DIFF'
, @cleanupTime = 5
, @cleanupMode = 'BEFORE_BACKUP'

-- Версия для обычного экземпляра --

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @databases = 'USER_DATABASES'
, @directoryPath = 'S:\BackupSQL\UserDB'
, @backupType = 'DIFF'
, @cleanupTime = 720
, @cleanupMode = 'BEFORE_BACKUP'


/*
    Task:
        DBA: Database LOG backup
    Step 1:
        Backup
*/

-- Версия для экземпляра с кластером --

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @availabilityGroups = 'CryptAG'
, @directoryPath = '\\rebacker\Backup'
, @backupType = 'LOG'
, @cleanupTime = 1
, @cleanupMode = 'BEFORE_BACKUP'

-- Версия для обычного экземпляра --

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @databases = 'USER_DATABASES'
, @directoryPath = 'S:\BackupSQL\UserDB'
, @backupType = 'LOG'
, @cleanupTime = 1
, @cleanupMode = 'BEFORE_BACKUP'


/*
    Task:
        DBA: Database FULL|DIFF|LOG backup
    Step 2:
        Copy
*/

-- Версия для обычного экземпляра --

USE msdb;

IF NOT EXISTS (SELECT 1 FROM sysjobs j JOIN sysjobactivity a ON a.job_id = j.job_id
               WHERE j.name = N'DBA: Copy database backup'
                   AND a.run_requested_date IS NOT NULL AND a.stop_execution_date IS NULL
                   AND session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity))
    EXEC sp_start_job 'DBA: Copy database backup'

-- Версия для экземпляра с зеркальным отображением --

USE msdb;

IF NOT EXISTS (SELECT 1 FROM sysjobs j JOIN sysjobactivity a ON a.job_id = j.job_id
               WHERE j.name = N'DBA: Copy database backup'
                   AND a.run_requested_date IS NOT NULL AND a.stop_execution_date IS NULL
                   AND session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity))
    IF (SELECT CASE WHEN SUM(mirroring_role) = COUNT(1) THEN 1 ELSE 2 END
            FROM sys.database_mirroring WHERE mirroring_role IS NOT NULL) = 1
        EXEC sp_start_job 'DBA: Copy database backup'

/*
    Task:
        DBA: Copy database backup
    Step 1:
        Copy backup
    Type:
        CmdExec
*/

-- Версия для обычного экземпляра с локальным хранением бэкапов --

C:\Scripts\mssql\copybackup.cmd I:\SQLBackups \\rebacker\Backup\tesb-eoks


/*
    Task:
        DBA: SystemDB FULL backup
    Step 1:
        Backup
*/

USE DBAtools;

EXEC dbo.usp_DatabaseBackup
  @databases = 'SYSTEM_DATABASES'
, @directoryPath = 'S:\BackupSQL\SystemDB'
, @backupType = 'FULL'
, @cleanupTime = 672
, @cleanupMode = 'BEFORE_BACKUP'