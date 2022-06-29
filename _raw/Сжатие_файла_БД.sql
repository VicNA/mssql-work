USE [TranscryptDataStorage]
GO

--ALTER DATABASE [roaming]  
--SET RECOVERY SIMPLE; 
--go

DBCC SHRINKFILE (N'TranscryptDataStorage' , NOTRUNCATE)
GO
DBCC SHRINKFILE (N'TranscryptDataStorage' , TRUNCATEONLY)
GO

--ALTER DATABASE [roaming]  
--SET RECOVERY FULL; 
--go