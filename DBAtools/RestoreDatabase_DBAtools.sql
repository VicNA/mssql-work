USE [master]
GO

IF EXISTS (SELECT 1 from sys.databases WHERE name = 'DBAtools')
    ALTER DATABASE [DBAtools] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [DBAtools] FROM  DISK = N'C:\ProgramFilesAdmin\DBAtools.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5, replace
GO

IF (SELECT DATABASEPROPERTYEX('DBAtools','UserAccess')) != 'MULTI_USER'
    ALTER DATABASE [DBAtools] SET MULTI_USER;
GO

USE DBAtools
GO

TRUNCATE TABLE CommandLog;